"""
Basic tests for the Terraform Agent.
"""

import pytest
import asyncio
from pathlib import Path
from agent.core.agent import TerraformAgent
from agent.core.config import get_config


@pytest.fixture
def config():
    """Get test configuration."""
    return get_config()


@pytest.fixture
def agent():
    """Create a test agent instance."""
    agent = TerraformAgent()
    return agent


import pytest_asyncio

@pytest_asyncio.fixture
async def async_agent():
    """Create a test agent instance for async tests."""
    agent = TerraformAgent()
    yield agent
    await agent.stop()


def test_config_loading(config):
    """Test configuration loading."""
    assert config.agent_model == "codellama:7b-instruct"
    assert config.temperature == 0.7
    assert config.max_tokens == 4096


def test_agent_initialization(agent):
    """Test agent initialization."""
    assert agent.config is not None
    assert agent.analyzer is not None


@pytest.mark.asyncio
async def test_agent_start_stop(async_agent):
    """Test agent start and stop."""
    # This test requires Ollama to be running
    try:
        await async_agent.start()
        assert async_agent.ollama_client is not None
    except Exception as e:
        pytest.skip(f"Ollama not available: {e}")
    finally:
        await async_agent.stop()


def test_terraform_parser():
    """Test Terraform parser."""
    from agent.terraform.parser import get_parser
    
    parser = get_parser()
    assert parser is not None
    assert parser.supported_extensions == {'.tf', '.tfvars', '.hcl'}


def test_git_repository():
    """Test Git repository integration."""
    from agent.git.repository import get_repository
    
    try:
        repo = get_repository()
        assert repo is not None
    except Exception as e:
        pytest.skip(f"Git repository not available: {e}")


if __name__ == "__main__":
    pytest.main([__file__]) 