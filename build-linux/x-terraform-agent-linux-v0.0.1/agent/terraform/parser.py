"""
Terraform parser and analyzer for understanding Terraform code.
"""

import re
import json
from pathlib import Path
from typing import Dict, List, Optional, Any, Set, Tuple
import hcl2
import yaml
import structlog
from ..core.exceptions import TerraformError

logger = structlog.get_logger(__name__)


class TerraformParser:
    """Parser for Terraform configuration files."""
    
    def __init__(self):
        self.supported_extensions = {'.tf', '.tfvars', '.hcl'}
    
    def parse_file(self, file_path: str) -> Dict[str, Any]:
        """Parse a Terraform file and return structured data."""
        try:
            file_path_obj = Path(file_path)
            if not file_path_obj.exists():
                raise TerraformError(f"File not found: {file_path}")
            
            if file_path_obj.suffix not in self.supported_extensions:
                raise TerraformError(f"Unsupported file type: {file_path}")
            
            content = file_path_obj.read_text(encoding='utf-8')
            
            if file_path_obj.suffix == '.tf':
                return self._parse_terraform_file(content, file_path)
            elif file_path_obj.suffix == '.tfvars':
                return self._parse_tfvars_file(content, file_path)
            elif file_path_obj.suffix == '.hcl':
                return self._parse_hcl_file(content, file_path)
            else:
                raise TerraformError(f"Unsupported file type: {file_path}")
                
        except Exception as e:
            raise TerraformError(f"Failed to parse file {file_path}: {e}")
    
    def _parse_terraform_file(self, content: str, file_path: str) -> Dict[str, Any]:
        """Parse a .tf file."""
        try:
            parsed = hcl2.loads(content)
            logger.debug(f"HCL2 parsed content: {parsed}")
            
            result = {
                "file_path": file_path,
                "file_type": "terraform",
                "providers": [],
                "resources": [],
                "data_sources": [],
                "variables": [],
                "outputs": [],
                "locals": [],
                "modules": [],
                "terraform_blocks": [],
                "errors": []
            }
            
            # HCL2 returns a dictionary with block types as keys
            for block_type, block_content in parsed.items():
                logger.debug(f"Block type: {block_type}, content: {block_content}")
                if block_type == "terraform":
                    result["terraform_blocks"].extend(self._extract_terraform_blocks(block_content))
                elif block_type == "provider":
                    result["providers"].extend(self._extract_providers(block_content))
                elif block_type == "resource":
                    result["resources"].extend(self._extract_resources(block_content))
                elif block_type == "data":
                    result["data_sources"].extend(self._extract_data_sources(block_content))
                elif block_type == "variable":
                    result["variables"].extend(self._extract_variables(block_content))
                elif block_type == "output":
                    result["outputs"].extend(self._extract_outputs(block_content))
                elif block_type == "locals":
                    result["locals"].extend(self._extract_locals(block_content))
                elif block_type == "module":
                    result["modules"].extend(self._extract_modules(block_content))
            
            logger.debug(f"Final result: {result}")
            return result
            
        except Exception as e:
            logger.error(f"Failed to parse Terraform file: {e}")
            return {
                "file_path": file_path,
                "file_type": "terraform",
                "error": str(e),
                "providers": [],
                "resources": [],
                "data_sources": [],
                "variables": [],
                "outputs": [],
                "locals": [],
                "modules": [],
                "terraform_blocks": []
            }
    
    def _parse_tfvars_file(self, content: str, file_path: str) -> Dict[str, Any]:
        """Parse a .tfvars file."""
        try:
            parsed = hcl2.loads(content)
            
            result = {
                "file_path": file_path,
                "file_type": "tfvars",
                "variables": {},
                "errors": []
            }
            
            # tfvars files contain variable assignments
            for block in parsed:
                if isinstance(block, dict):
                    result["variables"].update(block)
            
            return result
            
        except Exception as e:
            return {
                "file_path": file_path,
                "file_type": "tfvars",
                "error": str(e),
                "variables": {}
            }
    
    def _parse_hcl_file(self, content: str, file_path: str) -> Dict[str, Any]:
        """Parse a .hcl file."""
        try:
            parsed = hcl2.loads(content)
            
            result = {
                "file_path": file_path,
                "file_type": "hcl",
                "content": parsed,
                "errors": []
            }
            
            return result
            
        except Exception as e:
            return {
                "file_path": file_path,
                "file_type": "hcl",
                "error": str(e),
                "content": {}
            }
    
    def _extract_terraform_blocks(self, blocks: List[Dict]) -> List[Dict]:
        """Extract terraform configuration blocks."""
        terraform_blocks = []
        for block in blocks:
            if isinstance(block, dict):
                terraform_blocks.append(block)
        return terraform_blocks
    
    def _extract_providers(self, providers: List[Dict]) -> List[Dict]:
        """Extract provider configurations."""
        provider_list = []
        for provider in providers:
            if isinstance(provider, dict):
                for provider_name, config in provider.items():
                    provider_list.append({
                        "name": provider_name,
                        "config": config
                    })
        return provider_list
    
    def _extract_resources(self, resources: List[Dict]) -> List[Dict]:
        """Extract resource configurations."""
        resource_list = []
        for resource in resources:
            if isinstance(resource, dict):
                # HCL2 structure: [{"aws_vpc": {"main": {"cidr_block": "10.0.0.0/16"}}}]
                for resource_type, resource_blocks in resource.items():
                    if isinstance(resource_blocks, dict):
                        for resource_name, config in resource_blocks.items():
                            resource_list.append({
                                "type": resource_type,
                                "name": resource_name,
                                "config": config
                            })
        return resource_list
    
    def _extract_data_sources(self, data_sources: List[Dict]) -> List[Dict]:
        """Extract data source configurations."""
        data_list = []
        for data_source in data_sources:
            if isinstance(data_source, dict):
                # HCL2 structure: [{"aws_ami": {"ubuntu": {"most_recent": True}}}]
                for data_type, data_blocks in data_source.items():
                    if isinstance(data_blocks, dict):
                        for data_name, config in data_blocks.items():
                            data_list.append({
                                "type": data_type,
                                "name": data_name,
                                "config": config
                            })
        return data_list
    
    def _extract_variables(self, variables: List[Dict]) -> List[Dict]:
        """Extract variable declarations."""
        variable_list = []
        for variable in variables:
            if isinstance(variable, dict):
                # HCL2 structure: [{"region": {"description": "AWS region", "type": "string"}}]
                for var_name, config in variable.items():
                    variable_list.append({
                        "name": var_name,
                        "config": config
                    })
        return variable_list
    
    def _extract_outputs(self, outputs: List[Dict]) -> List[Dict]:
        """Extract output declarations."""
        output_list = []
        for output in outputs:
            if isinstance(output, dict):
                # HCL2 structure: [{"vpc_id": {"value": "aws_vpc.main.id"}}]
                for output_name, config in output.items():
                    output_list.append({
                        "name": output_name,
                        "config": config
                    })
        return output_list
    
    def _extract_locals(self, locals_blocks: List[Dict]) -> List[Dict]:
        """Extract local value declarations."""
        local_list = []
        for local_block in locals_blocks:
            if isinstance(local_block, dict):
                local_list.append(local_block)
        return local_list
    
    def _extract_modules(self, modules: List[Dict]) -> List[Dict]:
        """Extract module declarations."""
        module_list = []
        for module in modules:
            if isinstance(module, dict):
                for module_name, config in module.items():
                    module_list.append({
                        "name": module_name,
                        "config": config
                    })
        return module_list


class TerraformAnalyzer:
    """Analyzer for Terraform configurations."""
    
    def __init__(self):
        self.parser = TerraformParser()
    
    def analyze_directory(self, directory_path: str) -> Dict[str, Any]:
        """Analyze all Terraform files in a directory."""
        try:
            directory = Path(directory_path)
            if not directory.exists():
                raise TerraformError(f"Directory not found: {directory_path}")
            
            analysis = {
                "directory": str(directory),
                "files": [],
                "summary": {
                    "total_files": 0,
                    "total_resources": 0,
                    "total_providers": 0,
                    "total_variables": 0,
                    "total_outputs": 0,
                    "providers": set(),
                    "resources": set(),
                    "data_sources": set(),
                    "variables": set(),
                    "outputs": set(),
                    "modules": set()
                },
                "dependencies": {},
                "errors": []
            }
            
            # Find all Terraform files
            terraform_files = list(directory.rglob("*.tf")) + list(directory.rglob("*.tfvars"))
            
            for file_path in terraform_files:
                try:
                    file_analysis = self.parser.parse_file(str(file_path))
                    analysis["files"].append(file_analysis)
                    analysis["summary"]["total_files"] += 1
                    
                    # Update summary
                    self._update_summary(analysis["summary"], file_analysis)
                    
                except Exception as e:
                    analysis["errors"].append({
                        "file": str(file_path),
                        "error": str(e)
                    })
            
            # Analyze dependencies
            analysis["dependencies"] = self._analyze_dependencies(analysis["files"])
            
            # Convert sets to lists for JSON serialization and update counts
            for key in analysis["summary"]:
                if isinstance(analysis["summary"][key], set):
                    analysis["summary"][key] = list(analysis["summary"][key])
            
            # Update total counts
            analysis["summary"]["total_resources"] = len(analysis["summary"]["resources"])
            analysis["summary"]["total_providers"] = len(analysis["summary"]["providers"])
            analysis["summary"]["total_variables"] = len(analysis["summary"]["variables"])
            analysis["summary"]["total_outputs"] = len(analysis["summary"]["outputs"])
            
            return analysis
            
        except Exception as e:
            raise TerraformError(f"Failed to analyze directory {directory_path}: {e}")
    
    def _update_summary(self, summary: Dict[str, Any], file_analysis: Dict[str, Any]):
        """Update analysis summary with file data."""
        if "providers" in file_analysis:
            for provider in file_analysis["providers"]:
                summary["providers"].add(provider.get("name", "unknown"))
        
        if "resources" in file_analysis:
            for resource in file_analysis["resources"]:
                summary["resources"].add(resource.get("type", "unknown"))
        
        if "data_sources" in file_analysis:
            for data_source in file_analysis["data_sources"]:
                summary["data_sources"].add(data_source.get("type", "unknown"))
        
        if "variables" in file_analysis:
            for variable in file_analysis["variables"]:
                summary["variables"].add(variable.get("name", "unknown"))
        
        if "outputs" in file_analysis:
            for output in file_analysis["outputs"]:
                summary["outputs"].add(output.get("name", "unknown"))
        
        if "modules" in file_analysis:
            for module in file_analysis["modules"]:
                summary["modules"].add(module.get("name", "unknown"))
    
    def _analyze_dependencies(self, files: List[Dict[str, Any]]) -> Dict[str, Any]:
        """Analyze dependencies between Terraform resources."""
        dependencies = {
            "resource_dependencies": {},
            "module_dependencies": {},
            "variable_dependencies": {}
        }
        
        # Build resource dependency graph
        for file_analysis in files:
            if "resources" in file_analysis:
                for resource in file_analysis["resources"]:
                    resource_id = f"{resource['type']}.{resource['name']}"
                    dependencies["resource_dependencies"][resource_id] = self._find_resource_dependencies(
                        resource, files
                    )
        
        return dependencies
    
    def _find_resource_dependencies(self, resource: Dict[str, Any], files: List[Dict[str, Any]]) -> List[str]:
        """Find dependencies for a specific resource."""
        dependencies = []
        resource_config = resource.get("config", {})
        
        # Look for references to other resources
        for file_analysis in files:
            if "resources" in file_analysis:
                for other_resource in file_analysis["resources"]:
                    other_id = f"{other_resource['type']}.{other_resource['name']}"
                    
                    # Check if this resource references the other resource
                    if self._resource_references_other(resource_config, other_id):
                        dependencies.append(other_id)
        
        return dependencies
    
    def _resource_references_other(self, config: Dict[str, Any], resource_id: str) -> bool:
        """Check if a resource configuration references another resource."""
        config_str = json.dumps(config)
        
        # Look for references like aws_instance.web.id or module.vpc.vpc_id
        patterns = [
            rf"{resource_id}\.",
            rf"data\.{resource_id}\.",
            rf"module\.{resource_id}\."
        ]
        
        for pattern in patterns:
            if re.search(pattern, config_str):
                return True
        
        return False
    
    def validate_configuration(self, file_path: str) -> Dict[str, Any]:
        """Validate a Terraform configuration file."""
        try:
            parsed = self.parser.parse_file(file_path)
            
            validation = {
                "file_path": file_path,
                "valid": True,
                "is_valid": True,  # Keep both for compatibility
                "errors": [],
                "warnings": [],
                "suggestions": []
            }
            
            # Check for common issues
            if "error" in parsed:
                validation["valid"] = False
                validation["is_valid"] = False
                validation["errors"].append(parsed["error"])
            
            # Check for missing required fields
            if "resources" in parsed:
                for resource in parsed["resources"]:
                    self._validate_resource(resource, validation)
            
            # Check for best practices
            self._check_best_practices(parsed, validation)
            
            return validation
            
        except Exception as e:
            return {
                "file_path": file_path,
                "valid": False,
                "is_valid": False,
                "error": str(e),
                "errors": [str(e)],
                "warnings": [],
                "suggestions": []
            }
    
    def _validate_resource(self, resource: Dict[str, Any], validation: Dict[str, Any]):
        """Validate a single resource."""
        resource_type = resource.get("type", "")
        config = resource.get("config", {})
        
        # Check for required fields based on resource type
        if resource_type.startswith("aws_"):
            if "tags" not in config:
                validation["warnings"].append(f"Resource {resource['name']} should have tags")
        
        # Check for common issues
        if "depends_on" in config and not config["depends_on"]:
            validation["warnings"].append(f"Resource {resource['name']} has empty depends_on")
    
    def _check_best_practices(self, parsed: Dict[str, Any], validation: Dict[str, Any]):
        """Check for Terraform best practices."""
        # Check for version constraints
        if "terraform_blocks" in parsed:
            for block in parsed["terraform_blocks"]:
                if "required_version" not in block:
                    validation["suggestions"].append("Consider adding required_version constraint")
        
        # Check for variable validation
        if "variables" in parsed:
            for variable in parsed["variables"]:
                config = variable.get("config", {})
                if "validation" not in config:
                    validation["suggestions"].append(f"Consider adding validation for variable {variable['name']}")


# Global instances
_parser = TerraformParser()
_analyzer = TerraformAnalyzer()


def get_parser() -> TerraformParser:
    """Get the global parser instance."""
    return _parser


def get_analyzer() -> TerraformAnalyzer:
    """Get the global analyzer instance."""
    return _analyzer 