"""
Custom exceptions for the Terraform Agent.
"""

from typing import Optional, Any, Dict


class AgentError(Exception):
    """Base exception for Terraform Agent errors."""
    
    def __init__(self, message: str, details: Optional[Dict[str, Any]] = None):
        self.message = message
        self.details = details or {}
        super().__init__(self.message)
    
    def __str__(self):
        if self.details:
            return f"{self.message} - Details: {self.details}"
        return self.message


class TerraformError(AgentError):
    """Exception raised for Terraform-related errors."""
    
    def __init__(self, message: str, terraform_output: Optional[str] = None, 
                 exit_code: Optional[int] = None):
        details = {}
        if terraform_output:
            details['terraform_output'] = terraform_output
        if exit_code is not None:
            details['exit_code'] = exit_code
        super().__init__(message, details)


class GitError(AgentError):
    """Exception raised for Git-related errors."""
    
    def __init__(self, message: str, git_command: Optional[str] = None,
                 git_output: Optional[str] = None):
        details = {}
        if git_command:
            details['git_command'] = git_command
        if git_output:
            details['git_output'] = git_output
        super().__init__(message, details)


class ModelError(AgentError):
    """Exception raised for AI model-related errors."""
    
    def __init__(self, message: str, model_name: Optional[str] = None,
                 response: Optional[str] = None):
        details = {}
        if model_name:
            details['model_name'] = model_name
        if response:
            details['response'] = response
        super().__init__(message, details)


class ConfigurationError(AgentError):
    """Exception raised for configuration-related errors."""
    
    def __init__(self, message: str, config_key: Optional[str] = None,
                 config_value: Optional[Any] = None):
        details = {}
        if config_key:
            details['config_key'] = config_key
        if config_value is not None:
            details['config_value'] = config_value
        super().__init__(message, details)


class ValidationError(AgentError):
    """Exception raised for validation errors."""
    
    def __init__(self, message: str, field: Optional[str] = None,
                 value: Optional[Any] = None):
        details = {}
        if field:
            details['field'] = field
        if value is not None:
            details['value'] = value
        super().__init__(message, details)


class ApprovalError(AgentError):
    """Exception raised when user approval is denied."""
    
    def __init__(self, message: str = "User approval denied", 
                 action: Optional[str] = None):
        details = {}
        if action:
            details['action'] = action
        super().__init__(message, details)


class DocumentationError(AgentError):
    """Exception raised for documentation-related errors."""
    
    def __init__(self, message: str, doc_path: Optional[str] = None):
        details = {}
        if doc_path:
            details['doc_path'] = doc_path
        super().__init__(message, details)


class SecurityError(AgentError):
    """Exception raised for security-related errors."""
    
    def __init__(self, message: str, security_check: Optional[str] = None):
        details = {}
        if security_check:
            details['security_check'] = security_check
        super().__init__(message, details) 