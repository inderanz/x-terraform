"""
Integration tests for the Terraform Agent.
"""

import pytest
import asyncio
import tempfile
import shutil
from pathlib import Path
from unittest.mock import Mock, patch, AsyncMock

from agent.core.agent import TerraformAgent
from agent.core.config import get_config
from agent.git.repository import GitRepository
from agent.terraform.parser import TerraformParser, TerraformAnalyzer
from agent.models.ollama_client import OllamaClient


@pytest.fixture
def temp_workspace():
    """Create a temporary workspace with Terraform files."""
    temp_dir = tempfile.mkdtemp()
    
    # Create sample Terraform files
    main_tf = Path(temp_dir) / "main.tf"
    main_tf.write_text("""
terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-west-2"
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = {
    Name = "main-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  
  tags = {
    Name = "public-subnet"
  }
}
""")
    
    variables_tf = Path(temp_dir) / "variables.tf"
    variables_tf.write_text("""
variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}
""")
    
    outputs_tf = Path(temp_dir) / "outputs.tf"
    outputs_tf.write_text("""
output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "subnet_id" {
  description = "Public subnet ID"
  value       = aws_subnet.public.id
}
""")
    
    yield temp_dir
    
    # Cleanup
    shutil.rmtree(temp_dir)


@pytest.fixture
def mock_ollama_client():
    """Mock Ollama client."""
    with patch('agent.models.ollama_client.OllamaClient') as mock_client:
        mock_instance = Mock(spec=OllamaClient)
        mock_instance.health_check = AsyncMock(return_value=True)
        mock_instance.generate = AsyncMock(return_value="Mock AI response")
        mock_instance.disconnect = AsyncMock()
        mock_client.return_value = mock_instance
        yield mock_instance


@pytest.fixture
def agent_with_mocks(mock_ollama_client, temp_workspace):
    """Create agent with mocked dependencies."""
    with patch('agent.git.repository.GitRepository') as mock_repo_class:
        mock_repo = Mock(spec=GitRepository)
        mock_repo.repo_path = Path(temp_workspace)
        mock_repo.get_repository_info.return_value = {
            "path": temp_workspace,
            "branch": "main",
            "commit": "test-commit",
            "is_dirty": False
        }
        mock_repo.find_terraform_files.return_value = [
            {"path": "main.tf", "absolute_path": f"{temp_workspace}/main.tf"},
            {"path": "variables.tf", "absolute_path": f"{temp_workspace}/variables.tf"},
            {"path": "outputs.tf", "absolute_path": f"{temp_workspace}/outputs.tf"}
        ]
        mock_repo_class.return_value = mock_repo
        
        agent = TerraformAgent()
        agent.repository = mock_repo
        return agent


class TestTerraformParser:
    """Test Terraform parser functionality."""
    
    def test_parse_terraform_file(self, temp_workspace):
        """Test parsing a Terraform file."""
        parser = TerraformParser()
        main_tf = Path(temp_workspace) / "main.tf"
        
        result = parser.parse_file(str(main_tf))
        
        assert result["file_type"] == "terraform"
        assert len(result["resources"]) == 2  # vpc and subnet
        assert len(result["providers"]) == 1  # aws provider
        assert len(result["terraform_blocks"]) == 1
        assert "errors" not in result or not result["errors"]
    
    def test_parse_variables_file(self, temp_workspace):
        """Test parsing a variables file."""
        parser = TerraformParser()
        variables_tf = Path(temp_workspace) / "variables.tf"
        
        result = parser.parse_file(str(variables_tf))
        
        assert result["file_type"] == "terraform"
        assert len(result["variables"]) == 2  # region and environment
        assert "errors" not in result or not result["errors"]
    
    def test_parse_outputs_file(self, temp_workspace):
        """Test parsing an outputs file."""
        parser = TerraformParser()
        outputs_tf = Path(temp_workspace) / "outputs.tf"
        
        result = parser.parse_file(str(outputs_tf))
        
        assert result["file_type"] == "terraform"
        assert len(result["outputs"]) == 2  # vpc_id and subnet_id
        assert "errors" not in result or not result["errors"]


class TestTerraformAnalyzer:
    """Test Terraform analyzer functionality."""
    
    def test_analyze_directory(self, temp_workspace):
        """Test analyzing a directory of Terraform files."""
        analyzer = TerraformAnalyzer()
        
        result = analyzer.analyze_directory(temp_workspace)
        
        assert "summary" in result
        assert "files" in result
        assert "dependencies" in result
        assert result["summary"]["total_files"] == 3
        assert result["summary"]["total_resources"] == 2
        assert result["summary"]["total_providers"] == 1
    
    def test_validate_configuration(self, temp_workspace):
        """Test configuration validation."""
        analyzer = TerraformAnalyzer()
        main_tf = Path(temp_workspace) / "main.tf"
        
        result = analyzer.validate_configuration(str(main_tf))
        
        assert "valid" in result
        assert "errors" in result
        assert "warnings" in result
        assert "best_practices" in result


class TestGitRepository:
    """Test Git repository integration."""
    
    def test_repository_initialization(self, temp_workspace):
        """Test repository initialization."""
        # Create a git repository
        import git
        repo = git.Repo.init(temp_workspace)
        
        # Add files to git
        repo.index.add(["main.tf", "variables.tf", "outputs.tf"])
        repo.index.commit("Initial commit")
        
        git_repo = GitRepository(temp_workspace)
        
        assert git_repo.repo is not None
        assert git_repo.repo_path == Path(temp_workspace)
    
    def test_find_terraform_files(self, temp_workspace):
        """Test finding Terraform files."""
        git_repo = GitRepository(temp_workspace)
        
        files = git_repo.find_terraform_files()
        
        assert len(files) == 3
        file_paths = [f["path"] for f in files]
        assert "main.tf" in file_paths
        assert "variables.tf" in file_paths
        assert "outputs.tf" in file_paths
    
    def test_get_file_content(self, temp_workspace):
        """Test getting file content."""
        git_repo = GitRepository(temp_workspace)
        
        content = git_repo.get_file_content("main.tf")
        
        assert content is not None
        assert "aws_vpc" in content
        assert "aws_subnet" in content


class TestTerraformAgent:
    """Test Terraform Agent functionality."""
    
    @pytest.mark.asyncio
    async def test_agent_initialization(self, agent_with_mocks):
        """Test agent initialization."""
        agent = agent_with_mocks
        
        assert agent.config is not None
        assert agent.analyzer is not None
        assert agent.repository is not None
    
    @pytest.mark.asyncio
    async def test_agent_start_stop(self, agent_with_mocks, mock_ollama_client):
        """Test agent start and stop."""
        agent = agent_with_mocks
        
        await agent.start()
        assert agent.ollama_client is not None
        
        await agent.stop()
    
    @pytest.mark.asyncio
    async def test_process_query(self, agent_with_mocks, mock_ollama_client):
        """Test processing a query."""
        agent = agent_with_mocks
        await agent.start()
        
        result = await agent.process_query("Create a VPC with public and private subnets")
        
        assert "response" in result
        assert "actions" in result
        assert "results" in result
        assert "context" in result
        # Don't check for exact response content since it's generated by AI
        assert isinstance(result["response"], str)
        assert len(result["response"]) > 0
    
    @pytest.mark.asyncio
    async def test_analyze_terraform_files(self, agent_with_mocks):
        """Test analyzing Terraform files."""
        agent = agent_with_mocks
        
        result = await agent.analyze_terraform_files()
        
        assert "summary" in result
        assert "files" in result
        assert "dependencies" in result
    
    @pytest.mark.asyncio
    async def test_validate_terraform_file(self, agent_with_mocks, temp_workspace):
        """Test validating a Terraform file."""
        agent = agent_with_mocks
        main_tf = Path(temp_workspace) / "main.tf"
        
        result = await agent.validate_terraform_file(str(main_tf))
        
        assert "valid" in result
        assert "errors" in result
        assert "warnings" in result


class TestConfiguration:
    """Test configuration management."""
    
    def test_config_loading(self):
        """Test configuration loading."""
        config = get_config()
        
        assert config.agent_model == "codellama:7b-instruct"
        assert config.temperature == 0.7
        assert config.max_tokens == 4096
        assert config.require_approval is True
    
    def test_config_validation(self):
        """Test configuration validation."""
        config = get_config()
        
        assert config.validate() is True
    
    def test_config_to_dict(self):
        """Test configuration serialization."""
        config = get_config()
        
        config_dict = config.to_dict()
        
        assert "agent_model" in config_dict
        assert "temperature" in config_dict
        assert "max_tokens" in config_dict


class TestOllamaClient:
    """Test Ollama client functionality."""
    
    @pytest.mark.asyncio
    async def test_health_check(self, mock_ollama_client):
        """Test health check."""
        client = mock_ollama_client
        
        result = await client.health_check()
        
        assert result is True
    
    @pytest.mark.asyncio
    async def test_generate_response(self, mock_ollama_client):
        """Test response generation."""
        client = mock_ollama_client
        
        response = await client.generate("Test prompt")
        
        assert response == "Mock AI response"
        client.generate.assert_called_once()


if __name__ == "__main__":
    pytest.main([__file__, "-v"]) 