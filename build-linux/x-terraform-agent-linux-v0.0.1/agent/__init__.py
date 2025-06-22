"""
Terraform Agent - A production-grade AI agent for Terraform development.

This package provides an offline-capable AI agent that specializes in Terraform
infrastructure as code, with git context awareness and interactive approval workflows.
"""

__version__ = "1.0.0"
__author__ = "Terraform Agent Team"
__description__ = "Production-grade AI agent for Terraform development"

from .core.agent import TerraformAgent
from .core.config import AgentConfig
from .core.exceptions import AgentError, TerraformError, GitError

__all__ = [
    "TerraformAgent",
    "AgentConfig", 
    "AgentError",
    "TerraformError",
    "GitError"
] 