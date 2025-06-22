# Terraform Agent Documentation

## Overview

The Terraform Agent is a production-grade AI assistant specifically designed for Terraform infrastructure as code development. It provides intelligent assistance, code generation, and problem-solving capabilities while working completely offline using local AI models.

## Features

### 🤖 AI-Powered Assistance
- **Local AI Models**: Uses Ollama with local models (no internet required)
- **Terraform Expertise**: Deep understanding of Terraform syntax and best practices
- **Context Awareness**: Understands your repository structure and current state
- **Interactive Mode**: Natural conversation interface

### 📁 Git Integration
- **Repository Analysis**: Automatically analyzes your Git repository
- **Change Tracking**: Understands modified, staged, and untracked files
- **Commit History**: Provides context from recent commits
- **Branch Awareness**: Works with different Git branches

### 🏗️ Terraform Specialization
- **Code Generation**: Create production-ready Terraform configurations
- **Validation**: Validate existing Terraform files
- **Best Practices**: Guide users toward Terraform best practices
- **Error Diagnosis**: Help diagnose and fix Terraform issues
- **Dependency Analysis**: Understand resource dependencies

### 🔒 Security & Safety
- **Approval Workflow**: Always asks before applying changes
- **Audit Logging**: Comprehensive logging of all actions
- **Offline Operation**: No data sent to external services
- **Local Processing**: All AI processing happens locally

## Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   User Input    │───▶│  Terraform      │───▶│  Ollama         │
│   (CLI/API)     │    │  Agent          │    │  Local Model    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │  Git Context    │
                       │  Repository     │
                       └─────────────────┘
                              │
                              ▼
                       ┌─────────────────┐
                       │  Terraform      │
                       │  Documentation  │
                       │  (Local)        │
                       └─────────────────┘
```

## Installation

### Prerequisites

1. **Ollama**: Install from [ollama.ai](https://ollama.ai)
2. **Python 3.11+**: For local development
3. **Docker & Docker Compose**: For containerized deployment
4. **Git**: For repository integration

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone <your-repo>
   cd x-terraform
   ```

2. **Initialize with your Terraform project**:
   ```bash
   ./scripts/init-agent.sh /path/to/your/terraform/project
   ```

3. **Start the agent**:
   ```bash
   ./scripts/agent-cli.sh start
   ```

## Usage

### Interactive Mode

Start an interactive session with the agent:

```bash
./scripts/agent-cli.sh start
```

Example conversation:
```
You: Create a VPC with public and private subnets
Agent: I'll help you create a VPC with public and private subnets. Here's a complete configuration:

```terraform
# VPC Configuration
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "main-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "private-subnet"
  }
}
```

Would you like me to create this file for you?
```

### Single Query Mode

Ask a specific question:

```bash
./scripts/agent-cli.sh query "What's wrong with my main.tf file?"
```

### Analysis Mode

Analyze your Terraform files:

```bash
./scripts/agent-cli.sh analyze
```

### Validation Mode

Validate a specific file:

```bash
./scripts/agent-cli.sh validate main.tf
```

## Configuration

### Environment Variables

The agent can be configured using environment variables:

```bash
# Agent Configuration
AGENT_MODEL=codellama:7b-instruct  # Ollama model to use
AGENT_TEMP=0.7                     # Temperature for responses
AGENT_MAX_TOKENS=4096              # Max tokens per response

# Terraform Configuration
TF_WORKSPACE=default               # Terraform workspace
TF_BACKEND_TYPE=local              # Backend type

# Git Configuration
GIT_REPO_PATH=/path/to/repo        # Path to git repository
GIT_BRANCH=main                    # Default branch

# Security Configuration
REQUIRE_APPROVAL=true              # Require user approval
AUDIT_LOG_ENABLED=true             # Enable audit logging
```

### Model Selection

The agent supports various Ollama models:

- `codellama:7b-instruct` - Best for code generation
- `llama2:7b-chat` - Good balance of performance and quality
- `mistral:7b-instruct` - Fast and efficient
- `qwen2.5:7b-instruct` - Excellent for technical tasks

## Docker Deployment

### Using Docker Compose

1. **Start the services**:
   ```bash
   docker-compose up -d
   ```

2. **Access the agent**:
   ```bash
   # Interactive mode
   docker exec -it terraform-agent python -m agent.main --interactive
   
   # Single query
   docker exec -it terraform-agent python -m agent.main "Create a VPC"
   ```

3. **View logs**:
   ```bash
   docker-compose logs -f terraform-agent
   ```

### Docker CLI

```bash
# Start with Docker
./scripts/agent-cli.sh --docker start

# Query with Docker
./scripts/agent-cli.sh --docker query "Analyze my Terraform files"
```

## Development

### Project Structure

```
x-terraform/
├── agent/                 # Core agent implementation
│   ├── core/             # Agent core logic
│   ├── terraform/        # Terraform-specific handlers
│   ├── git/              # Git integration
│   └── models/           # AI model interfaces
├── docs/                 # Documentation
├── scripts/              # Utility scripts
├── tests/                # Test suite
├── docker/               # Docker configurations
└── config/               # Configuration files
```

### Running Tests

```bash
# Install test dependencies
pip install -r requirements.txt

# Run tests
pytest tests/

# Run with coverage
pytest tests/ --cov=agent
```

### Development Setup

1. **Create virtual environment**:
   ```bash
   python3 -m venv venv
   source venv/bin/activate
   ```

2. **Install dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

3. **Install development dependencies**:
   ```bash
   pip install -e .
   ```

4. **Run the agent**:
   ```bash
   python -m agent.main --interactive
   ```

## Troubleshooting

### Common Issues

1. **Ollama not running**:
   ```bash
   ollama serve
   ```

2. **Model not available**:
   ```bash
   ollama pull codellama:7b-instruct
   ```

3. **Permission denied**:
   ```bash
   chmod +x scripts/*.sh
   ```

4. **Python dependencies**:
   ```bash
   pip install -r requirements.txt
   ```

### Logs

- **Local mode**: Check `logs/` directory
- **Docker mode**: `docker-compose logs terraform-agent`

### Health Checks

```bash
# Check Ollama health
curl http://localhost:11434/api/tags

# Check agent health
curl http://localhost:8000/health
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests
5. Submit a pull request

## License

MIT License - see LICENSE file for details.

## Support

For issues and questions:
- Check the documentation in `/docs`
- Review existing issues
- Create a new issue with detailed information

---

**Built with ❤️ for the Terraform community** 