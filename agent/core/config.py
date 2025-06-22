"""
Configuration management for the Terraform Agent.
"""

import os
from pathlib import Path
from typing import Optional, Dict, Any
from pydantic import Field, validator
from pydantic_settings import BaseSettings
import structlog

logger = structlog.get_logger(__name__)


class AgentConfig(BaseSettings):
    """Configuration for the Terraform Agent."""
    
    # Agent Configuration
    agent_model: str = Field(
        default="codellama:7b-instruct",
        description="Ollama model to use for AI responses"
    )
    temperature: float = Field(
        default=0.7,
        ge=0.0,
        le=2.0,
        description="Temperature for AI model responses"
    )
    max_tokens: int = Field(
        default=4096,
        ge=1,
        le=8192,
        description="Maximum tokens per response"
    )
    
    # Terraform Configuration
    terraform_workspace: str = Field(
        default="default",
        description="Terraform workspace to use"
    )
    terraform_backend_type: str = Field(
        default="local",
        description="Terraform backend type"
    )
    
    # Git Configuration
    git_repo_path: Optional[str] = Field(
        default=None,
        description="Path to git repository"
    )
    git_branch: str = Field(
        default="main",
        description="Default git branch"
    )
    
    # Logging Configuration
    log_level: str = Field(
        default="INFO",
        description="Logging level"
    )
    log_format: str = Field(
        default="json",
        description="Log format (json, console)"
    )
    
    # API Configuration
    api_host: str = Field(
        default="0.0.0.0",
        description="API host address"
    )
    api_port: int = Field(
        default=8000,
        ge=1,
        le=65535,
        description="API port"
    )
    
    # Ollama Configuration
    ollama_host: str = Field(
        default="http://localhost:11434",
        description="Ollama API host"
    )
    ollama_timeout: int = Field(
        default=300,
        description="Ollama API timeout in seconds"
    )
    
    # Security Configuration
    require_approval: bool = Field(
        default=True,
        description="Require user approval for changes"
    )
    audit_log_enabled: bool = Field(
        default=True,
        description="Enable audit logging"
    )
    
    # File Paths - Use relative paths for local development
    data_dir: Path = Field(
        default=Path("./data"),
        description="Data directory"
    )
    logs_dir: Path = Field(
        default=Path("./logs"),
        description="Logs directory"
    )
    docs_dir: Path = Field(
        default=Path("./docs"),
        description="Terraform documentation directory"
    )
    
    @validator('git_repo_path')
    def validate_git_repo_path(cls, v):
        """Validate git repository path."""
        if v is not None:
            path = Path(v)
            if not path.exists():
                logger.warning(f"Git repository path does not exist: {v}")
                return None
            if not (path / ".git").exists():
                logger.warning(f"Path is not a git repository: {v}")
                return None
        return v
    
    @validator('data_dir', 'logs_dir', 'docs_dir')
    def create_directories(cls, v):
        """Create directories if they don't exist."""
        try:
            v.mkdir(parents=True, exist_ok=True)
        except (OSError, PermissionError) as e:
            logger.warning(f"Could not create directory {v}: {e}")
            # Use current directory as fallback
            v = Path.cwd() / v.name
            v.mkdir(parents=True, exist_ok=True)
        return v
    
    class Config:
        env_prefix = ""
        case_sensitive = False
        env_file = ".env"
        protected_namespaces = ('settings_',)
    
    def to_dict(self) -> Dict[str, Any]:
        """Convert configuration to dictionary."""
        return self.dict()
    
    def update_from_env(self):
        """Update configuration from environment variables."""
        for field_name, field in self.__fields__.items():
            env_var = field.field_info.extra.get('env', field_name.upper())
            if env_var in os.environ:
                setattr(self, field_name, os.environ[env_var])
    
    def validate(self) -> bool:
        """Validate configuration."""
        try:
            # Validate required directories
            for path_name in ['data_dir', 'logs_dir', 'docs_dir']:
                path = getattr(self, path_name)
                if not path.exists():
                    logger.warning(f"Creating directory: {path}")
                    path.mkdir(parents=True, exist_ok=True)
            
            # Validate model name format
            if not self.agent_model or ':' not in self.agent_model:
                raise ValueError("Model name must be in format 'model:tag'")
            
            logger.info("Configuration validation successful")
            return True
            
        except Exception as e:
            logger.error(f"Configuration validation failed: {e}")
            return False


# Global configuration instance
config = AgentConfig()

def get_config() -> AgentConfig:
    """Get the global configuration instance."""
    return config

def reload_config() -> AgentConfig:
    """Reload configuration from environment."""
    global config
    config = AgentConfig()
    config.update_from_env()
    config.validate()
    return config 