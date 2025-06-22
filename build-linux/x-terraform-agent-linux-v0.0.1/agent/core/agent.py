"""
Main Terraform Agent implementation.
"""

import asyncio
import json
import os
from pathlib import Path
from typing import Dict, List, Optional, Any, AsyncGenerator
import structlog
from rich.console import Console
from rich.prompt import Prompt, Confirm
from rich.panel import Panel
from rich.text import Text
from rich.table import Table
from rich.syntax import Syntax
from datetime import datetime

from .config import get_config
from .exceptions import AgentError, ApprovalError
from ..models.ollama_client import get_ollama_client, OllamaClient
from ..git.repository import get_repository, GitRepository
from ..terraform.parser import get_analyzer, TerraformAnalyzer

logger = structlog.get_logger(__name__)
console = Console()


class TerraformAgent:
    """Main Terraform Agent class."""
    
    def __init__(self):
        self.config = get_config()
        self.ollama_client: Optional[OllamaClient] = None
        self.repository: Optional[GitRepository] = None
        self.analyzer: Optional[TerraformAnalyzer] = None
        self.conversation_history: List[Dict[str, str]] = []
        self.current_directory: Optional[str] = None
        
        # Initialize components
        self._initialize_components()
    
    def _initialize_components(self):
        """Initialize agent components."""
        try:
            # Initialize Terraform analyzer
            self.analyzer = get_analyzer()
            
            # Initialize Git repository (if available)
            try:
                self.repository = get_repository()
                logger.info("Git repository initialized")
            except Exception as e:
                logger.warning(f"Git repository not available: {e}")
            
            logger.info("Terraform Agent initialized successfully")
            
        except Exception as e:
            logger.error(f"Failed to initialize agent components: {e}")
            raise AgentError(f"Initialization failed: {e}")
    
    async def start(self):
        """Start the agent and initialize Ollama connection."""
        try:
            self.ollama_client = await get_ollama_client()
            
            # Check if Ollama is healthy
            if not await self.ollama_client.health_check():
                raise AgentError("Ollama is not healthy")
            
            logger.info("Terraform Agent started successfully")
            
        except Exception as e:
            logger.error(f"Failed to start agent: {e}")
            raise AgentError(f"Start failed: {e}")
    
    async def stop(self):
        """Stop the agent and cleanup resources."""
        try:
            if self.ollama_client:
                await self.ollama_client.disconnect()
            
            logger.info("Terraform Agent stopped")
            
        except Exception as e:
            logger.error(f"Error during agent shutdown: {e}")
    
    def set_working_directory(self, directory: str):
        """Set the working directory for file operations."""
        self.current_directory = directory
        logger.info(f"Working directory set to: {directory}")
    
    async def process_query(
        self, 
        query: str, 
        context: Optional[Dict[str, Any]] = None,
        require_approval: Optional[bool] = None
    ) -> Dict[str, Any]:
        """Process a user query and return a response."""
        try:
            require_approval = require_approval if require_approval is not None else self.config.require_approval
            
            # Build context
            full_context = await self._build_context(context)
            
            # Generate AI response
            response = await self._generate_response(query, full_context)
            
            # Parse response for actions
            actions = self._parse_actions(response)
            
            # Execute actions if any
            if actions and require_approval:
                if not await self._request_approval(actions, response):
                    raise ApprovalError("User denied approval for actions")
            
            if actions:
                results = await self._execute_actions(actions)
            else:
                results = {}
            
            # Update conversation history
            self.conversation_history.append({
                "user": query,
                "assistant": response,
                "actions": actions,
                "results": results
            })
            
            return {
                "response": response,
                "actions": actions,
                "results": results,
                "context": full_context
            }
            
        except Exception as e:
            logger.error(f"Failed to process query: {e}")
            return {
                "error": str(e),
                "response": f"I encountered an error: {e}",
                "actions": [],
                "results": {}
            }
    
    async def _build_context(self, additional_context: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
        """Build comprehensive context for the AI model."""
        context = {
            "agent_info": {
                "name": "X-Terraform Agent",
                "version": "0.0.1",
                "release_date": "2024-06-22",
                "capabilities": [
                    "Terraform code generation and analysis",
                    "Local file processing (no git required)",
                    "Configuration validation and best practices",
                    "Code review and suggestions",
                    "Infrastructure planning and optimization",
                    "Error diagnosis and fixes",
                    "Latest Terraform documentation integration"
                ],
                "supported_terraform_version": ">= 1.0",
                "documentation_source": "https://developer.hashicorp.com/terraform",
                "documentation_last_updated": "2024-06-22"
            },
            "configuration": self.config.to_dict(),
            "conversation_history": self.conversation_history[-5:],  # Last 5 exchanges
        }
        
        # Add local file context (works without git)
        if self.current_directory:
            try:
                context["local_files"] = self._get_local_terraform_files()
                
                # Analyze current directory
                analysis = self.analyzer.analyze_directory(self.current_directory)
                context["terraform_analysis"] = analysis
                
            except Exception as e:
                logger.warning(f"Failed to build local file context: {e}")
        
        # Add Git repository context (if available)
        if self.repository:
            try:
                context["git"] = self.repository.get_repository_info()
                
                # Add Terraform file analysis
                terraform_files = self.repository.find_terraform_files()
                if terraform_files:
                    context["terraform_files"] = terraform_files
                    
                    # Analyze current directory
                    if self.repository.repo_path:
                        analysis = self.analyzer.analyze_directory(str(self.repository.repo_path))
                        context["terraform_analysis"] = analysis
                        
            except Exception as e:
                logger.warning(f"Failed to build Git context: {e}")
        
        # Add additional context
        if additional_context:
            context.update(additional_context)
        
        return context
    
    def _get_local_terraform_files(self) -> Dict[str, Any]:
        """Get Terraform files from local directory."""
        if not self.current_directory:
            return {}
        
        directory = Path(self.current_directory)
        if not directory.exists():
            return {}
        
        terraform_files = []
        for file_path in directory.rglob("*.tf"):
            try:
                content = file_path.read_text(encoding='utf-8')
                terraform_files.append({
                    "path": str(file_path),
                    "name": file_path.name,
                    "size": len(content),
                    "content": content,
                    "relative_path": str(file_path.relative_to(directory))
                })
            except Exception as e:
                logger.warning(f"Failed to read file {file_path}: {e}")
        
        return {
            "directory": str(directory),
            "files": terraform_files,
            "total_files": len(terraform_files)
        }
    
    async def _generate_response(self, query: str, context: Dict[str, Any]) -> str:
        """Generate AI response using Ollama."""
        try:
            # Build system prompt
            system_prompt = self._build_system_prompt(context)
            
            # Build user prompt
            user_prompt = self._build_user_prompt(query, context)
            
            # Generate response
            response = await self.ollama_client.generate(
                prompt=user_prompt,
                system_prompt=system_prompt,
                temperature=self.config.temperature,
                max_tokens=self.config.max_tokens
            )
            
            return response
            
        except Exception as e:
            logger.error(f"Failed to generate response: {e}")
            raise AgentError(f"Response generation failed: {e}")
    
    def _build_system_prompt(self, context: Dict[str, Any]) -> str:
        """Build system prompt for the AI model."""
        agent_info = context.get("agent_info", {})
        
        system_prompt = f"""You are {agent_info.get('name', 'Terraform Agent')} version {agent_info.get('version', '1.0.0')}, an AI-powered assistant for Terraform infrastructure as code.

CAPABILITIES:
{chr(10).join(f"- {cap}" for cap in agent_info.get('capabilities', []))}

TERRAFORM KNOWLEDGE:
- You have access to the latest Terraform documentation from {agent_info.get('documentation_source', 'https://developer.hashicorp.com/terraform')}
- Documentation is current as of {agent_info.get('documentation_last_updated', '2024-06-22')}
- You understand Terraform {agent_info.get('supported_terraform_version', '>= 1.0')} syntax and best practices
- You can analyze, validate, and suggest improvements for Terraform configurations

RESPONSE FORMAT:
1. Provide clear, actionable advice
2. Reference specific Terraform documentation when applicable
3. Include code examples when helpful
4. Suggest best practices and security considerations
5. If suggesting changes, provide the complete updated code
6. Always explain the reasoning behind your suggestions

CODE REVIEW GUIDELINES:
- Check for security best practices
- Validate syntax and structure
- Suggest performance optimizations
- Ensure proper resource naming conventions
- Verify provider configurations
- Check for potential cost optimizations

When analyzing Terraform code, always provide:
1. Summary of what the code does
2. Potential issues or improvements
3. Best practices recommendations
4. Security considerations
5. Cost optimization suggestions (if applicable)

Be helpful, accurate, and follow HashiCorp's official Terraform best practices."""
        
        return system_prompt
    
    def _build_user_prompt(self, query: str, context: Dict[str, Any]) -> str:
        """Build user prompt with context."""
        prompt = f"User Query: {query}\n\n"
        
        # Add local file context
        if "local_files" in context:
            local_files = context["local_files"]
            prompt += f"WORKING DIRECTORY: {local_files.get('directory', 'Not set')}\n"
            prompt += f"TERRAFORM FILES FOUND: {local_files.get('total_files', 0)}\n\n"
            
            for file_info in local_files.get("files", []):
                prompt += f"FILE: {file_info['relative_path']}\n"
                prompt += f"CONTENT:\n{file_info['content']}\n\n"
        
        # Add analysis context
        if "terraform_analysis" in context:
            analysis = context["terraform_analysis"]
            prompt += f"ANALYSIS SUMMARY:\n"
            prompt += f"- Total files: {analysis.get('total_files', 0)}\n"
            prompt += f"- Resources: {len(analysis.get('resources', []))}\n"
            prompt += f"- Providers: {len(analysis.get('providers', []))}\n"
            prompt += f"- Variables: {len(analysis.get('variables', []))}\n"
            prompt += f"- Outputs: {len(analysis.get('outputs', []))}\n\n"
        
        # Add conversation history
        if context.get("conversation_history"):
            prompt += "CONVERSATION HISTORY:\n"
            for exchange in context["conversation_history"]:
                prompt += f"User: {exchange.get('user', '')}\n"
                prompt += f"Assistant: {exchange.get('assistant', '')}\n\n"
        
        return prompt
    
    def _parse_actions(self, response: str) -> List[Dict[str, Any]]:
        """Parse actions from AI response."""
        actions = []
        
        # Look for action markers in the response
        # This is a simple implementation - in production, you might want more sophisticated parsing
        
        # Check for file creation/modification patterns
        if "```terraform" in response or "```hcl" in response:
            # Extract code blocks
            import re
            code_blocks = re.findall(r'```(?:terraform|hcl)\n(.*?)\n```', response, re.DOTALL)
            
            for i, code in enumerate(code_blocks):
                actions.append({
                    "type": "code_generation",
                    "content": code,
                    "description": f"Generated Terraform code block {i+1}"
                })
        
        return actions
    
    async def _request_approval(self, actions: List[Dict[str, Any]], response: str) -> bool:
        """Request user approval for actions."""
        console.print(Panel(
            f"🤖 Terraform Agent Response\n\n{response}",
            title="AI Response"
        ))
        
        if actions:
            actions_text = "🔧 Proposed Actions:\n" + "\n".join([f"• {action['description']}" for action in actions])
            console.print(Panel(
                actions_text,
                title="Actions"
            ))
            
            return Confirm.ask("Do you approve these actions?", default=False)
        
        return True
    
    async def _execute_actions(self, actions: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Execute approved actions."""
        results = {}
        
        for i, action in enumerate(actions):
            try:
                if action["type"] == "code_generation":
                    # For now, just return the generated code
                    # In a full implementation, you might write to files
                    results[f"action_{i}"] = {
                        "type": "code_generation",
                        "status": "completed",
                        "content": action["content"]
                    }
                
            except Exception as e:
                results[f"action_{i}"] = {
                    "type": action["type"],
                    "status": "failed",
                    "error": str(e)
                }
        
        return results
    
    async def analyze_terraform_files(self, directory: Optional[str] = None) -> Dict[str, Any]:
        """Analyze Terraform files in the given directory."""
        try:
            if directory is None:
                if self.repository and self.repository.repo_path:
                    directory = str(self.repository.repo_path)
                else:
                    # Use current working directory as fallback
                    directory = str(Path.cwd())
            
            # Ensure directory exists
            if not Path(directory).exists():
                raise AgentError(f"Directory not found: {directory}")
            
            analysis = self.analyzer.analyze_directory(directory)
            return analysis
            
        except Exception as e:
            logger.error(f"Failed to analyze Terraform files: {e}")
            raise AgentError(f"Analysis failed: {e}")
    
    async def validate_terraform_file(self, file_path: str) -> Dict[str, Any]:
        """Validate a specific Terraform file."""
        try:
            validation = self.analyzer.validate_configuration(file_path)
            return validation
            
        except Exception as e:
            logger.error(f"Failed to validate Terraform file: {e}")
            raise AgentError(f"Validation failed: {e}")
    
    async def get_repository_status(self) -> Dict[str, Any]:
        """Get current repository status."""
        try:
            if not self.repository:
                return {"error": "No repository available"}
            
            return self.repository.get_repository_info()
            
        except Exception as e:
            logger.error(f"Failed to get repository status: {e}")
            return {"error": str(e)}
    
    async def interactive_mode(self):
        """Start interactive mode for the agent."""
        console.print(Panel(
            "🚀 Terraform Agent Interactive Mode\n\n"
            "✨ Offered by https://anzx.ai/ (Personal project of Inder Chauhan)\n"
            "🤖 Part of the X-agents Team - Always learning, always evolving!\n"
            "🙏 Thanks to its Developer Inder Chauhan for this amazing tool!\n\n"
            "💻 Do contribute to this project on https://github.com/inderanz/x-terraform\n"
            "🎉 Happy Terraforming!\n\n"
            "Type 'quit' to exit, 'help' for commands",
            title="Welcome to Interactive Mode"
        ))
        
        while True:
            try:
                query = Prompt.ask("\n[bold blue]You[/bold blue]")
                
                if query.lower() in ['quit', 'exit', 'q']:
                    break
                elif query.lower() == 'help':
                    self._show_help()
                    continue
                elif query.lower() == 'status':
                    await self._show_status()
                    continue
                elif query.lower() == 'analyze':
                    await self._show_analysis()
                    continue
                
                # Process the query
                result = await self.process_query(query)
                
                if "error" in result:
                    console.print(f"[red]Error: {result['error']}[/red]")
                else:
                    console.print(Panel(
                        result["response"],
                        title="🤖 Agent Response"
                    ))
                
            except KeyboardInterrupt:
                console.print("\n[yellow]Interrupted by user[/yellow]")
                break
            except Exception as e:
                console.print(f"[red]Error: {e}[/red]")
    
    def _show_help(self):
        """Show help information."""
        help_text = """
Available Commands:
- help: Show this help message
- status: Show repository and agent status
- analyze: Analyze current Terraform files
- quit/exit/q: Exit interactive mode

You can also ask questions like:
- "Create a VPC with public and private subnets"
- "What's wrong with my main.tf file?"
- "How do I use Terraform modules?"
- "Review my Terraform configuration"

💻 Do contribute to this project on https://github.com/inderanz/x-terraform
🙏 Thanks to its Developer Inder Chauhan for this amazing tool!
        """
        console.print(Panel(help_text, title="Help"))
    
    async def _show_status(self):
        """Show current status."""
        status = await self.get_repository_status()
        console.print(Panel(
            json.dumps(status, indent=2),
            title="Repository Status"
        ))
    
    async def _show_analysis(self):
        """Show Terraform analysis."""
        analysis = await self.analyze_terraform_files()
        console.print(Panel(
            json.dumps(analysis.get("summary", {}), indent=2),
            title="Terraform Analysis"
        ))
    
    async def review_code(self, file_path: Optional[str] = None) -> Dict[str, Any]:
        """Review Terraform code and provide suggestions."""
        try:
            if not file_path and self.current_directory:
                # Review all Terraform files in current directory
                return await self._review_directory()
            elif file_path:
                return await self._review_single_file(file_path)
            else:
                raise AgentError("No file path or working directory specified")
                
        except Exception as e:
            logger.error(f"Failed to review code: {e}")
            return {
                "error": str(e),
                "suggestions": [],
                "issues": [],
                "improvements": []
            }
    
    async def _review_directory(self) -> Dict[str, Any]:
        """Review all Terraform files in the current directory."""
        if not self.current_directory:
            raise AgentError("No working directory set")
        
        directory = Path(self.current_directory)
        terraform_files = list(directory.rglob("*.tf"))
        
        if not terraform_files:
            return {
                "message": "No Terraform files found in the directory",
                "suggestions": [],
                "issues": [],
                "improvements": []
            }
        
        all_suggestions = []
        all_issues = []
        all_improvements = []
        
        for file_path in terraform_files:
            file_review = await self._review_single_file(str(file_path))
            all_suggestions.extend(file_review.get("suggestions", []))
            all_issues.extend(file_review.get("issues", []))
            all_improvements.extend(file_review.get("improvements", []))
        
        return {
            "directory": str(directory),
            "files_reviewed": len(terraform_files),
            "suggestions": all_suggestions,
            "issues": all_issues,
            "improvements": all_improvements
        }
    
    async def _review_single_file(self, file_path: str) -> Dict[str, Any]:
        """Review a single Terraform file."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                raise AgentError(f"File not found: {file_path}")
            
            content = file_path_obj.read_text(encoding='utf-8')
            
            # Analyze the file
            analysis = self.analyzer.validate_configuration(file_path)
            
            # Generate review using AI
            review_query = f"Please review this Terraform file and provide suggestions for improvements, security best practices, and potential issues:\n\n{content}"
            
            context = {
                "file_path": file_path,
                "file_content": content,
                "analysis": analysis
            }
            
            response = await self._generate_response(review_query, context)
            
            # Parse the response for structured feedback
            suggestions = self._extract_suggestions(response)
            issues = self._extract_issues(response)
            improvements = self._extract_improvements(response)
            
            return {
                "file_path": file_path,
                "file_size": len(content),
                "suggestions": suggestions,
                "issues": issues,
                "improvements": improvements,
                "analysis": analysis,
                "ai_review": response
            }
            
        except Exception as e:
            logger.error(f"Failed to review file {file_path}: {e}")
            return {
                "file_path": file_path,
                "error": str(e),
                "suggestions": [],
                "issues": [],
                "improvements": []
            }
    
    def _extract_suggestions(self, response: str) -> List[str]:
        """Extract suggestions from AI response."""
        suggestions = []
        lines = response.split('\n')
        for line in lines:
            if any(keyword in line.lower() for keyword in ['suggest', 'recommend', 'consider', 'should']):
                suggestions.append(line.strip())
        return suggestions
    
    def _extract_issues(self, response: str) -> List[str]:
        """Extract issues from AI response."""
        issues = []
        lines = response.split('\n')
        for line in lines:
            if any(keyword in line.lower() for keyword in ['issue', 'problem', 'error', 'warning', 'security risk']):
                issues.append(line.strip())
        return issues
    
    def _extract_improvements(self, response: str) -> List[str]:
        """Extract improvements from AI response."""
        improvements = []
        lines = response.split('\n')
        for line in lines:
            if any(keyword in line.lower() for keyword in ['improve', 'optimize', 'enhance', 'better']):
                improvements.append(line.strip())
        return improvements
    
    async def suggest_fixes(self, file_path: str, issue_description: str) -> Dict[str, Any]:
        """Suggest fixes for specific issues in a Terraform file."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                raise AgentError(f"File not found: {file_path}")
            
            content = file_path_obj.read_text(encoding='utf-8')
            
            fix_query = f"Please suggest specific fixes for this issue in the Terraform file: {issue_description}\n\nFile content:\n{content}"
            
            context = {
                "file_path": file_path,
                "file_content": content,
                "issue": issue_description
            }
            
            response = await self._generate_response(fix_query, context)
            
            return {
                "file_path": file_path,
                "issue": issue_description,
                "suggested_fix": response,
                "original_content": content
            }
            
        except Exception as e:
            logger.error(f"Failed to suggest fixes for {file_path}: {e}")
            return {
                "error": str(e),
                "file_path": file_path,
                "issue": issue_description
            }
    
    async def apply_suggestions(self, file_path: str, suggestions: List[str], require_approval: bool = True) -> Dict[str, Any]:
        """Apply suggested changes to a Terraform file."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                raise AgentError(f"File not found: {file_path}")
            
            original_content = file_path_obj.read_text(encoding='utf-8')
            
            # Generate updated content
            update_query = f"Please update this Terraform file with the following suggestions:\n\nSuggestions:\n{chr(10).join(suggestions)}\n\nOriginal content:\n{original_content}"
            
            context = {
                "file_path": file_path,
                "original_content": original_content,
                "suggestions": suggestions
            }
            
            updated_content = await self._generate_response(update_query, context)
            
            # Extract the updated code from the response
            updated_code = self._extract_code_from_response(updated_content)
            
            if not updated_code:
                return {
                    "error": "Could not extract updated code from response",
                    "file_path": file_path,
                    "original_content": original_content
                }
            
            # Show diff and request approval
            if require_approval:
                console.print(f"\n[bold yellow]Proposed changes for {file_path}:[/bold yellow]")
                console.print(f"[bold]Original:[/bold]")
                console.print(Syntax(original_content, "hcl", theme="monokai"))
                console.print(f"\n[bold]Updated:[/bold]")
                console.print(Syntax(updated_code, "hcl", theme="monokai"))
                
                if not Confirm.ask("Apply these changes?"):
                    return {
                        "cancelled": True,
                        "file_path": file_path,
                        "message": "User cancelled the operation"
                    }
            
            # Create backup
            backup_path = f"{file_path}.backup.{datetime.now().strftime('%Y%m%d_%H%M%S')}"
            file_path_obj.rename(backup_path)
            
            # Write updated content
            file_path_obj.write_text(updated_code, encoding='utf-8')
            
            return {
                "success": True,
                "file_path": file_path,
                "backup_path": backup_path,
                "changes_applied": True,
                "original_content": original_content,
                "updated_content": updated_code
            }
            
        except Exception as e:
            logger.error(f"Failed to apply suggestions to {file_path}: {e}")
            return {
                "error": str(e),
                "file_path": file_path
            }
    
    def _extract_code_from_response(self, response: str) -> str:
        """Extract code blocks from AI response."""
        # Look for code blocks marked with ```
        import re
        code_blocks = re.findall(r'```(?:hcl|terraform)?\n(.*?)\n```', response, re.DOTALL)
        if code_blocks:
            return code_blocks[0].strip()
        
        # If no code blocks, try to extract the entire response
        return response.strip()


# Global agent instance
_agent: Optional[TerraformAgent] = None


async def get_agent() -> TerraformAgent:
    """Get the global agent instance."""
    global _agent
    if _agent is None:
        _agent = TerraformAgent()
        await _agent.start()
    return _agent


async def close_agent():
    """Close the global agent instance."""
    global _agent
    if _agent:
        await _agent.stop()
        _agent = None 