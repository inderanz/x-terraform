"""
Main entry point for the Terraform Agent.
"""

import asyncio
import sys
import argparse
from pathlib import Path
from typing import Optional
import structlog
from rich.console import Console
from rich.panel import Panel
from rich.text import Text
from rich.table import Table

from .core.agent import get_agent, close_agent
from .core.config import get_config, reload_config

console = Console()
logger = structlog.get_logger(__name__)


async def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description="X-Terraform Agent v0.0.1 - AI-powered Terraform assistant with offline capabilities",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  terraform-agent --interactive                    # Start interactive mode
  terraform-agent "Create a VPC"                   # Single query
  terraform-agent --dir workspace --analyze        # Analyze specific directory
  terraform-agent --dir workspace --review         # Review Terraform code
  terraform-agent --dir workspace --validate       # Validate Terraform files
  terraform-agent --dir workspace "What does this code do?"  # Query about specific code
        """
    )
    
    parser.add_argument(
        "query",
        nargs="?",
        help="Query to process (optional if using --interactive)"
    )
    
    parser.add_argument(
        "--interactive", "-i",
        action="store_true",
        help="Start interactive mode"
    )
    
    parser.add_argument(
        "--dir", "-d",
        type=str,
        help="Path to directory containing Terraform files (no git required)"
    )
    
    parser.add_argument(
        "--repo", "-r",
        type=str,
        help="Path to git repository (optional, for git integration)"
    )
    
    parser.add_argument(
        "--analyze", "-a",
        action="store_true",
        help="Analyze Terraform files in the directory"
    )
    
    parser.add_argument(
        "--review", "-R",
        action="store_true",
        help="Review Terraform code and provide suggestions"
    )
    
    parser.add_argument(
        "--validate", "-v",
        action="store_true",
        help="Validate Terraform files"
    )
    
    parser.add_argument(
        "--status", "-s",
        action="store_true",
        help="Show agent status and capabilities"
    )
    
    parser.add_argument(
        "--model", "-m",
        type=str,
        help="Ollama model to use"
    )
    
    parser.add_argument(
        "--no-approval",
        action="store_true",
        help="Skip approval prompts"
    )
    
    parser.add_argument(
        "--verbose", "-V",
        action="store_true",
        help="Enable verbose logging"
    )
    
    parser.add_argument(
        "--config",
        type=str,
        help="Path to configuration file"
    )
    
    args = parser.parse_args()
    
    try:
        # Setup logging
        setup_logging(args.verbose)
        
        # Load configuration
        if args.config:
            load_configuration(args.config)
        
        # Update configuration from command line arguments
        if args.model:
            config = get_config()
            config.agent_model = args.model
        
        # Show banner
        show_banner()
        
        # Get agent instance
        agent = await get_agent()
        
        # Set working directory if specified
        if args.dir:
            agent.set_working_directory(args.dir)
        
        # Set repository path if specified (optional)
        if args.repo:
            from .git.repository import set_repository_path
            set_repository_path(args.repo)
            # Reinitialize agent with new repository
            agent = await get_agent()
            if args.dir:
                agent.set_working_directory(args.dir)
        
        # Handle different modes
        if args.interactive:
            await agent.interactive_mode()
        elif args.analyze:
            await handle_analyze(agent)
        elif args.review:
            await handle_review(agent)
        elif args.validate:
            await handle_validate(agent)
        elif args.status:
            await handle_status(agent)
        elif args.query:
            await handle_query(agent, args.query, not args.no_approval)
        else:
            # Default to interactive mode
            await agent.interactive_mode()
    
    except KeyboardInterrupt:
        console.print("\n[yellow]Interrupted by user[/yellow]")
    except Exception as e:
        console.print(f"[red]Error: {e}[/red]")
        logger.error(f"Application error: {e}")
        sys.exit(1)
    finally:
        # Cleanup
        await close_agent()


def setup_logging(verbose: bool):
    """Setup logging configuration."""
    import logging
    
    log_level = logging.DEBUG if verbose else logging.INFO
    
    structlog.configure(
        processors=[
            structlog.stdlib.filter_by_level,
            structlog.stdlib.add_logger_name,
            structlog.stdlib.add_log_level,
            structlog.stdlib.PositionalArgumentsFormatter(),
            structlog.processors.TimeStamper(fmt="iso"),
            structlog.processors.StackInfoRenderer(),
            structlog.processors.format_exc_info,
            structlog.processors.UnicodeDecoder(),
            structlog.processors.JSONRenderer()
        ],
        context_class=dict,
        logger_factory=structlog.stdlib.LoggerFactory(),
        wrapper_class=structlog.stdlib.BoundLogger,
        cache_logger_on_first_use=True,
    )
    
    logging.basicConfig(
        format="%(message)s",
        stream=sys.stdout,
        level=log_level,
    )


def load_configuration(config_path: str):
    """Load configuration from file."""
    try:
        config_file = Path(config_path)
        if not config_file.exists():
            console.print(f"[red]Configuration file not found: {config_path}[/red]")
            return
        
        # Load environment variables from file
        from dotenv import load_dotenv
        load_dotenv(config_file)
        
        # Reload configuration
        reload_config()
        
        console.print(f"[green]Configuration loaded from: {config_path}[/green]")
        
    except Exception as e:
        console.print(f"[red]Failed to load configuration: {e}[/red]")


def show_banner():
    """Show application banner."""
    # Create an attractive banner with project information
    banner_text = Text()
    banner_text.append("🚀 ", style="bold blue")
    banner_text.append("X-Terraform Agent v0.0.1", style="bold blue")
    banner_text.append("\n\n", style="white")
    banner_text.append("✨ ", style="bold yellow")
    banner_text.append("Terraform Agent offered by ", style="white")
    banner_text.append("https://anzx.ai/", style="bold cyan")
    banner_text.append("\n", style="white")
    banner_text.append("🌟 ", style="bold yellow")
    banner_text.append("Personal project of ", style="white")
    banner_text.append("Inder Chauhan", style="bold green")
    banner_text.append(" (not affiliated with any bank)", style="white")
    banner_text.append("\n", style="white")
    banner_text.append("🤖 ", style="bold yellow")
    banner_text.append("Part of the ", style="white")
    banner_text.append("X-agents Team", style="bold magenta")
    banner_text.append(" - Always learning, always evolving!", style="white")
    banner_text.append("\n\n", style="white")
    banner_text.append("🙏 ", style="bold yellow")
    banner_text.append("Thanks to its Developer ", style="white")
    banner_text.append("Inder Chauhan", style="bold green")
    banner_text.append(" for this amazing tool!", style="white")
    banner_text.append("\n\n", style="white")
    banner_text.append("💻 ", style="bold yellow")
    banner_text.append("Do contribute to this project on ", style="white")
    banner_text.append("https://github.com/inderanz/x-terraform", style="bold cyan")
    banner_text.append("\n", style="white")
    banner_text.append("🎉 ", style="bold yellow")
    banner_text.append("Happy Terraforming!", style="bold green")
    
    banner = Panel(
        banner_text,
        subtitle="AI-powered Terraform assistant with offline capabilities",
        border_style="blue",
        padding=(1, 2)
    )
    console.print(banner)
    
    # Show capabilities
    capabilities_table = Table(title="Capabilities", show_header=True, header_style="bold magenta")
    capabilities_table.add_column("Feature", style="cyan")
    capabilities_table.add_column("Description", style="white")
    
    capabilities_table.add_row("Local File Processing", "Works with local Terraform files (no git required)")
    capabilities_table.add_row("Code Review", "AI-powered code review and suggestions")
    capabilities_table.add_row("Best Practices", "Latest Terraform best practices from HashiCorp")
    capabilities_table.add_row("Offline Mode", "Fully functional without internet connection")
    capabilities_table.add_row("Documentation", "References latest Terraform docs (as of 2024-06-22)")
    capabilities_table.add_row("Code Generation", "Generate production-ready Terraform configurations")
    
    console.print(capabilities_table)


async def handle_analyze(agent):
    """Handle analyze command."""
    console.print("\n[bold blue]Analyzing Terraform files...[/bold blue]")
    
    if not agent.current_directory:
        console.print("[red]No working directory set. Use --dir to specify a directory.[/red]")
        return
    
    try:
        analysis = await agent.analyze_terraform_files(agent.current_directory)
        
        # Display analysis results
        console.print("\n[bold green]Analysis Results:[/bold green]")
        
        analysis_table = Table(title="Terraform Analysis", show_header=True, header_style="bold magenta")
        analysis_table.add_column("Metric", style="cyan")
        analysis_table.add_column("Value", style="white")
        
        if "summary" in analysis:
            summary = analysis["summary"]
            analysis_table.add_row("Total Files", str(summary.get("total_files", 0)))
            analysis_table.add_row("Providers", ", ".join(summary.get("providers", [])))
            analysis_table.add_row("Resources", ", ".join(summary.get("resources", [])))
            analysis_table.add_row("Variables", ", ".join(summary.get("variables", [])))
            analysis_table.add_row("Outputs", ", ".join(summary.get("outputs", [])))
        
        console.print(analysis_table)
        
    except Exception as e:
        console.print(f"[red]Analysis failed: {e}[/red]")


async def handle_review(agent):
    """Handle review command."""
    console.print("\n[bold blue]Reviewing Terraform code...[/bold blue]")
    
    if not agent.current_directory:
        console.print("[red]No working directory set. Use --dir to specify a directory.[/red]")
        return
    
    try:
        review = await agent.review_code()
        
        if "error" in review:
            console.print(f"[red]Review failed: {review['error']}[/red]")
            return
        
        # Display review results
        console.print(f"\n[bold green]Code Review Results:[/bold green]")
        console.print(f"Directory: {review.get('directory', 'Unknown')}")
        console.print(f"Files reviewed: {review.get('files_reviewed', 0)}")
        
        if review.get("suggestions"):
            console.print(f"\n[bold yellow]Suggestions ({len(review['suggestions'])}):[/bold yellow]")
            for i, suggestion in enumerate(review["suggestions"], 1):
                console.print(f"{i}. {suggestion}")
        
        if review.get("issues"):
            console.print(f"\n[bold red]Issues ({len(review['issues'])}):[/bold red]")
            for i, issue in enumerate(review["issues"], 1):
                console.print(f"{i}. {issue}")
        
        if review.get("improvements"):
            console.print(f"\n[bold green]Improvements ({len(review['improvements'])}):[/bold green]")
            for i, improvement in enumerate(review["improvements"], 1):
                console.print(f"{i}. {improvement}")
        
    except Exception as e:
        console.print(f"[red]Review failed: {e}[/red]")


async def handle_validate(agent):
    """Handle validate command."""
    console.print("\n[bold blue]Validating Terraform files...[/bold blue]")
    
    if not agent.current_directory:
        console.print("[red]No working directory set. Use --dir to specify a directory.[/red]")
        return
    
    try:
        directory = Path(agent.current_directory)
        terraform_files = list(directory.rglob("*.tf"))
        
        if not terraform_files:
            console.print("[yellow]No Terraform files found in the directory.[/yellow]")
            return
        
        validation_table = Table(title="Validation Results", show_header=True, header_style="bold magenta")
        validation_table.add_column("File", style="cyan")
        validation_table.add_column("Status", style="white")
        validation_table.add_column("Issues", style="white")
        
        for file_path in terraform_files:
            try:
                validation = agent.analyzer.validate_configuration(str(file_path))
                
                if validation.get("errors"):
                    status = "[red]❌ Invalid[/red]"
                    issues = ", ".join(validation["errors"])
                else:
                    status = "[green]✅ Valid[/green]"
                    issues = "None"
                
                validation_table.add_row(
                    str(file_path.relative_to(directory)),
                    status,
                    issues
                )
                
            except Exception as e:
                validation_table.add_row(
                    str(file_path.relative_to(directory)),
                    "[red]❌ Error[/red]",
                    str(e)
                )
        
        console.print(validation_table)
        
    except Exception as e:
        console.print(f"[red]Validation failed: {e}[/red]")


async def handle_status(agent):
    """Handle status command."""
    console.print("\n[bold blue]Agent Status:[/bold blue]")
    
    status_table = Table(title="X-Terraform Agent Status", show_header=True, header_style="bold magenta")
    status_table.add_column("Component", style="cyan")
    status_table.add_column("Status", style="white")
    status_table.add_column("Details", style="white")
    
    # Agent status
    status_table.add_row("Agent", "[green]✅ Running[/green]", "X-Terraform Agent v0.0.1")
    
    # Ollama status
    try:
        if agent.ollama_client:
            status_table.add_row("Ollama", "[green]✅ Connected[/green]", "Model available")
        else:
            status_table.add_row("Ollama", "[red]❌ Not connected[/red]", "No connection")
    except:
        status_table.add_row("Ollama", "[red]❌ Error[/red]", "Connection failed")
    
    # Working directory
    if agent.current_directory:
        status_table.add_row("Working Directory", "[green]✅ Set[/green]", agent.current_directory)
    else:
        status_table.add_row("Working Directory", "[yellow]⚠️ Not set[/yellow]", "Use --dir to specify")
    
    # Git repository
    if agent.repository:
        status_table.add_row("Git Repository", "[green]✅ Available[/green]", "Git integration enabled")
    else:
        status_table.add_row("Git Repository", "[yellow]⚠️ Not available[/yellow]", "Optional - not required")
    
    # Terraform documentation
    status_table.add_row("Documentation", "[green]✅ Current[/green]", "Latest as of 2024-06-22")
    
    console.print(status_table)
    
    # Show capabilities
    console.print(f"\n[bold green]Capabilities:[/bold green]")
    console.print("• Local file processing (no git required)")
    console.print("• AI-powered code review and suggestions")
    console.print("• Latest Terraform best practices")
    console.print("• Offline operation with local models")
    console.print("• Code generation and validation")
    console.print("• Security and cost optimization suggestions")


async def handle_query(agent, query: str, require_approval: bool):
    """Handle query command."""
    console.print(f"\n[bold blue]Processing query: {query}[/bold blue]")
    
    try:
        result = await agent.process_query(query, require_approval=require_approval)
        
        if "error" in result:
            console.print(f"[red]Error: {result['error']}[/red]")
            return
        
        # Display response
        console.print(f"\n[bold green]🤖 Agent Response:[/bold green]")
        console.print(result["response"])
        
        # Display any actions taken
        if result.get("actions"):
            console.print(f"\n[bold yellow]Actions taken:[/bold yellow]")
            for action in result["actions"]:
                console.print(f"• {action}")
        
    except Exception as e:
        console.print(f"[red]Query failed: {e}[/red]")


if __name__ == "__main__":
    asyncio.run(main()) 