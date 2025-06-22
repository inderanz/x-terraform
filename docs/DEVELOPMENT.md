# Development Guide

This document provides comprehensive guidance for developing and contributing to the Terraform Agent project.

## Table of Contents

1. [Development Setup](#development-setup)
2. [Project Structure](#project-structure)
3. [Architecture Overview](#architecture-overview)
4. [Testing](#testing)
5. [Code Style](#code-style)
6. [Debugging](#debugging)
7. [Contributing](#contributing)
8. [Troubleshooting](#troubleshooting)

## Development Setup

### Prerequisites

- Python 3.8+
- Git
- Docker (optional, for containerized development)
- Ollama (for AI model support)

### Quick Start

1. **Clone the repository:**
   ```bash
   git clone <repository-url>
   cd x-terraform
   ```

2. **Run the setup script:**
   ```bash
   # For local development
   ./scripts/setup.sh --mode local --ollama
   
   # For Docker development
   ./scripts/setup.sh --mode docker --ollama
   
   # For both local and Docker
   ./scripts/setup.sh --mode both --ollama --test
   ```

3. **Initialize with a Terraform project:**
   ```bash
   ./scripts/init-agent.sh /path/to/your/terraform/project
   ```

4. **Start development:**
   ```bash
   # Local mode
   ./scripts/agent-cli.sh start
   
   # Docker mode
   ./scripts/agent-cli.sh --docker start
   ```

### Manual Setup

If you prefer manual setup:

1. **Create virtual environment:**
   ```bash
   python3 -m venv venv
   source venv/bin/activate  # On Windows: venv\Scripts\activate
   ```

2. **Install dependencies:**
   ```bash
   pip install -r requirements.txt
   pip install -e .
   ```

3. **Install Ollama:**
   ```bash
   curl -fsSL https://ollama.ai/install.sh | sh
   ollama serve &
   ollama pull codellama:7b-instruct
   ```

4. **Create environment file:**
   ```bash
   cp config/default.env .env
   # Edit .env with your configuration
   ```

## Project Structure

```
x-terraform/
├── agent/                     # Core agent implementation
│   ├── core/                 # Core functionality
│   │   ├── agent.py         # Main agent class
│   │   ├── config.py        # Configuration management
│   │   └── exceptions.py    # Custom exceptions
│   ├── git/                 # Git integration
│   │   └── repository.py    # Git repository wrapper
│   ├── models/              # AI model interfaces
│   │   └── ollama_client.py # Ollama client
│   ├── terraform/           # Terraform-specific code
│   │   └── parser.py        # Terraform parser and analyzer
│   └── main.py              # Entry point
├── config/                   # Configuration files
│   └── default.env          # Default environment variables
├── docs/                     # Documentation
├── scripts/                  # Utility scripts
│   ├── setup.sh             # Development setup
│   ├── init-agent.sh        # Agent initialization
│   └── agent-cli.sh         # CLI wrapper
├── tests/                    # Test suite
│   ├── test_agent.py        # Basic tests
│   └── test_integration.py  # Integration tests
├── workspace/                # Sample Terraform files
├── docker/                   # Docker configuration
│   └── Dockerfile           # Docker image definition
├── docker-compose.yml       # Docker Compose configuration
├── requirements.txt         # Python dependencies
├── setup.py                 # Package setup
└── README.md                # Project documentation
```

## Architecture Overview

### Core Components

1. **TerraformAgent** (`agent/core/agent.py`)
   - Main agent class that orchestrates all functionality
   - Handles query processing, context building, and action execution
   - Manages conversation history and approval workflows

2. **Configuration** (`agent/core/config.py`)
   - Pydantic-based configuration management
   - Environment variable support
   - Validation and type safety

3. **OllamaClient** (`agent/models/ollama_client.py`)
   - Async client for Ollama API
   - Model management and response generation
   - Health checks and error handling

4. **GitRepository** (`agent/git/repository.py`)
   - Git repository integration
   - File discovery and content retrieval
   - Commit history and diff analysis

5. **TerraformParser** (`agent/terraform/parser.py`)
   - HCL2-based Terraform file parsing
   - Configuration analysis and validation
   - Dependency resolution

### Data Flow

```
User Query → Agent → Context Building → AI Generation → Action Parsing → Execution → Response
     ↓
Git Context + Terraform Analysis + Configuration + History
```

### Key Design Principles

1. **Modularity**: Each component is self-contained with clear interfaces
2. **Async-First**: All I/O operations are asynchronous for better performance
3. **Error Handling**: Comprehensive error handling with custom exceptions
4. **Configuration**: Environment-based configuration with validation
5. **Testing**: Extensive test coverage with mocking support

## Testing

### Running Tests

```bash
# Run all tests
pytest tests/ -v

# Run specific test file
pytest tests/test_agent.py -v

# Run with coverage
pytest tests/ --cov=agent --cov-report=html

# Run integration tests only
pytest tests/test_integration.py -v

# Run tests in Docker
docker-compose run --rm terraform-agent python -m pytest tests/ -v
```

### Test Structure

- **Unit Tests**: Test individual components in isolation
- **Integration Tests**: Test component interactions
- **Mock Tests**: Test with mocked external dependencies
- **Fixtures**: Reusable test data and setup

### Writing Tests

```python
import pytest
from unittest.mock import Mock, patch, AsyncMock
from agent.core.agent import TerraformAgent

@pytest.fixture
def mock_ollama_client():
    """Mock Ollama client for testing."""
    with patch('agent.models.ollama_client.OllamaClient') as mock_client:
        mock_instance = Mock()
        mock_instance.generate = AsyncMock(return_value="Test response")
        mock_client.return_value = mock_instance
        yield mock_instance

@pytest.mark.asyncio
async def test_agent_query_processing(mock_ollama_client):
    """Test query processing functionality."""
    agent = TerraformAgent()
    await agent.start()
    
    result = await agent.process_query("Test query")
    
    assert "response" in result
    assert result["response"] == "Test response"
```

## Code Style

### Python Style Guide

- Follow PEP 8 for code formatting
- Use type hints for all function parameters and return values
- Use docstrings for all public functions and classes
- Keep functions small and focused
- Use meaningful variable and function names

### Code Formatting

```bash
# Format code with black
black agent/ tests/

# Sort imports with isort
isort agent/ tests/

# Check code style with flake8
flake8 agent/ tests/

# Type checking with mypy
mypy agent/
```

### Pre-commit Hooks

Create a `.pre-commit-config.yaml` file:

```yaml
repos:
  - repo: https://github.com/psf/black
    rev: 23.11.0
    hooks:
      - id: black
        language_version: python3
  - repo: https://github.com/pycqa/isort
    rev: 5.12.0
    hooks:
      - id: isort
  - repo: https://github.com/pycqa/flake8
    rev: 6.1.0
    hooks:
      - id: flake8
```

## Debugging

### Local Debugging

1. **Enable verbose logging:**
   ```bash
   export LOG_LEVEL=DEBUG
   ./scripts/agent-cli.sh --verbose start
   ```

2. **Use Python debugger:**
   ```python
   import pdb; pdb.set_trace()
   ```

3. **Debug with VS Code:**
   Create `.vscode/launch.json`:
   ```json
   {
     "version": "0.2.0",
     "configurations": [
       {
         "name": "Python: Terraform Agent",
         "type": "python",
         "request": "launch",
         "program": "${workspaceFolder}/agent/main.py",
         "args": ["--interactive"],
         "console": "integratedTerminal",
         "env": {
           "LOG_LEVEL": "DEBUG"
         }
       }
     ]
   }
   ```

### Docker Debugging

1. **Debug container:**
   ```bash
   docker-compose run --rm terraform-agent python -m pdb -m agent.main --interactive
   ```

2. **Check logs:**
   ```bash
   docker-compose logs -f terraform-agent
   ```

3. **Access container shell:**
   ```bash
   docker-compose exec terraform-agent /bin/bash
   ```

## Contributing

### Development Workflow

1. **Create a feature branch:**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes:**
   - Follow the code style guidelines
   - Add tests for new functionality
   - Update documentation as needed

3. **Run tests:**
   ```bash
   pytest tests/ -v
   ```

4. **Format code:**
   ```bash
   black agent/ tests/
   isort agent/ tests/
   ```

5. **Commit your changes:**
   ```bash
   git add .
   git commit -m "feat: add your feature description"
   ```

6. **Push and create pull request:**
   ```bash
   git push origin feature/your-feature-name
   ```

### Commit Message Format

Use conventional commits format:

- `feat:` New feature
- `fix:` Bug fix
- `docs:` Documentation changes
- `style:` Code style changes
- `refactor:` Code refactoring
- `test:` Test changes
- `chore:` Maintenance tasks

### Pull Request Guidelines

1. **Title**: Clear and descriptive
2. **Description**: Explain what and why, not how
3. **Tests**: Include tests for new functionality
4. **Documentation**: Update docs if needed
5. **Screenshots**: For UI changes

## Troubleshooting

### Common Issues

1. **Ollama not found:**
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh
   
   # Start Ollama service
   ollama serve &
   
   # Check if running
   curl http://localhost:11434/api/tags
   ```

2. **Python version issues:**
   ```bash
   # Check Python version
   python3 --version
   
   # Use specific Python version
   ./scripts/setup.sh --python python3.9
   ```

3. **Docker issues:**
   ```bash
   # Clean Docker environment
   docker-compose down --remove-orphans
   docker system prune -f
   
   # Rebuild
   docker-compose build --no-cache
   ```

4. **Import errors:**
   ```bash
   # Reinstall in development mode
   pip install -e .
   
   # Check PYTHONPATH
   export PYTHONPATH="${PYTHONPATH}:$(pwd)"
   ```

### Performance Issues

1. **Slow AI responses:**
   - Use smaller models (e.g., `codellama:7b-instruct`)
   - Reduce `max_tokens` in configuration
   - Use GPU acceleration if available

2. **Memory issues:**
   - Reduce batch sizes
   - Use streaming responses
   - Monitor memory usage

### Logging

Enable debug logging for troubleshooting:

```bash
export LOG_LEVEL=DEBUG
export LOG_FORMAT=console
```

Check logs in:
- Local: `./logs/`
- Docker: `docker-compose logs terraform-agent`

## Support

For additional help:

1. Check the [README.md](../README.md) for basic usage
2. Review existing [issues](../../issues)
3. Create a new issue with detailed information
4. Join the community discussions

---

**Happy coding! 🚀** 