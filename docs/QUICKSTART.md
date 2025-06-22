# Quick Start Guide

Get the Terraform Agent up and running in minutes!

## Prerequisites

- **Python 3.8+** (or Docker)
- **Git** (for repository integration)
- **Ollama** (for AI models)

## Option 1: Automated Setup (Recommended)

### 1. Clone and Setup

```bash
git clone <your-repo-url>
cd x-terraform

# Run the automated setup
./scripts/setup.sh --mode local --ollama --test
```

This will:
- ✅ Install Python dependencies
- ✅ Install Ollama and pull the default model
- ✅ Create virtual environment
- ✅ Run tests to verify everything works
- ✅ Create configuration files

### 2. Initialize with Your Project

```bash
# Point to your Terraform project
./scripts/init-agent.sh /path/to/your/terraform/project
```

### 3. Start Using the Agent

```bash
# Start interactive mode
./scripts/agent-cli.sh start

# Or ask a specific question
./scripts/agent-cli.sh query "Create a VPC with public and private subnets"
```

## Option 2: Docker Setup

### 1. Setup with Docker

```bash
git clone <your-repo-url>
cd x-terraform

# Setup Docker environment
./scripts/setup.sh --mode docker --ollama
```

### 2. Start with Docker

```bash
# Start the agent with Docker
./scripts/agent-cli.sh --docker start

# Or run a specific command
./scripts/agent-cli.sh --docker query "Review my main.tf"
```

## Option 3: Manual Setup

### 1. Install Dependencies

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt
pip install -e .
```

### 2. Install Ollama

```bash
# Install Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve &

# Pull the default model
ollama pull codellama:7b-instruct
```

### 3. Configure Environment

```bash
# Copy default configuration
cp config/default.env .env

# Edit configuration (optional)
nano .env
```

### 4. Initialize and Start

```bash
# Initialize with your project
./scripts/init-agent.sh /path/to/your/terraform/project

# Start the agent
python -m agent.main --interactive
```

## First Steps

### 1. Basic Commands

```bash
# Interactive mode (recommended for beginners)
./scripts/agent-cli.sh start

# Single query
./scripts/agent-cli.sh query "Help me understand my Terraform configuration"

# Analyze your project
./scripts/agent-cli.sh analyze

# Validate specific file
./scripts/agent-cli.sh validate main.tf

# Check status
./scripts/agent-cli.sh status
```

### 2. Example Queries

```bash
# Generate new resources
./scripts/agent-cli.sh query "Create an AWS VPC with public and private subnets"

# Review existing code
./scripts/agent-cli.sh query "Review my main.tf and suggest improvements"

# Fix issues
./scripts/agent-cli.sh query "I'm getting an error with my AWS provider configuration"

# Best practices
./scripts/agent-cli.sh query "What are the best practices for organizing Terraform modules?"
```

### 3. Interactive Mode

When you start interactive mode, you can:

- Ask questions about your Terraform code
- Get suggestions for improvements
- Generate new configurations
- Validate your setup
- Get help with errors

Example session:
```
🤖 Terraform Agent v1.0.0
📁 Repository: /path/to/your/project
🔧 Model: codellama:7b-instruct

> What resources do I have in my project?
[Agent analyzes your Terraform files and responds]

> Create a new security group for my web servers
[Agent generates the security group configuration]

> Review my variables.tf
[Agent reviews and suggests improvements]
```

## Configuration

### Environment Variables

Key configuration options in `.env`:

```bash
# AI Model
AGENT_MODEL=codellama:7b-instruct  # Change model here
AGENT_TEMP=0.7                     # Response creativity (0.0-2.0)
AGENT_MAX_TOKENS=4096              # Max response length

# Terraform
TF_WORKSPACE=default               # Terraform workspace
TF_BACKEND_TYPE=local              # Backend type

# Security
REQUIRE_APPROVAL=true              # Ask before making changes
AUDIT_LOG_ENABLED=true             # Log all actions
```

### Available Models

- `codellama:7b-instruct` - Best for code generation (default)
- `llama2:7b-chat` - Good balance of performance and quality
- `mistral:7b-instruct` - Fast and efficient
- `qwen2.5:7b-instruct` - Excellent for technical tasks

## Troubleshooting

### Common Issues

1. **"Ollama not found"**
   ```bash
   # Install Ollama
   curl -fsSL https://ollama.ai/install.sh | sh
   ollama serve &
   ```

2. **"Python not found"**
   ```bash
   # Use specific Python version
   ./scripts/setup.sh --python python3.9
   ```

3. **"Docker not found"**
   ```bash
   # Install Docker first, then run
   ./scripts/setup.sh --mode docker
   ```

4. **"Model not available"**
   ```bash
   # Pull the model
   ollama pull codellama:7b-instruct
   ```

### Getting Help

- Check logs: `./scripts/agent-cli.sh logs`
- Enable debug mode: `./scripts/agent-cli.sh --verbose start`
- View documentation: `docs/DEVELOPMENT.md`
- Check issues: GitHub issues page

## Next Steps

1. **Explore Features**: Try different commands and queries
2. **Customize**: Modify `.env` for your preferences
3. **Integrate**: Use in your CI/CD pipeline
4. **Contribute**: Check `docs/DEVELOPMENT.md` for contribution guidelines

## Examples

### Project Analysis

```bash
# Get overview of your project
./scripts/agent-cli.sh analyze

# Output:
# 📊 Project Analysis
# ├── Files: 5 Terraform files
# ├── Resources: 12 resources
# ├── Providers: 2 providers (aws, kubernetes)
# ├── Variables: 8 variables
# └── Outputs: 4 outputs
```

### Code Generation

```bash
# Generate a complete VPC setup
./scripts/agent-cli.sh query "Create a complete VPC with public and private subnets, NAT gateway, and security groups"

# The agent will generate:
# - VPC configuration
# - Subnet configurations
# - Route tables
# - Security groups
# - NAT gateway
# - Variables and outputs
```

### Code Review

```bash
# Review your configuration
./scripts/agent-cli.sh query "Review my main.tf and suggest security improvements"

# The agent will:
# - Analyze your code
# - Identify security issues
# - Suggest improvements
# - Provide best practices
```

---

**Ready to get started? Run `./scripts/setup.sh --mode local --ollama` and begin your Terraform journey! 🚀** 