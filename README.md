# X-Terraform Agent v0.0.1

🚀 **AI-powered Terraform assistant with offline capabilities**

X-Terraform Agent is a comprehensive AI assistant for Terraform infrastructure as code, designed to work completely offline with local models and files. It provides intelligent code analysis, review, and generation capabilities without requiring internet connectivity or Git repositories.

## ✨ Key Features

### 🔒 **Offline-First Design**
- **No internet required** - Works completely offline with local Ollama models
- **No Git dependency** - Processes local Terraform files directly
- **Self-contained** - Includes all necessary components for standalone operation

### 🤖 **AI-Powered Capabilities**
- **Code Review & Analysis** - Intelligent review of Terraform configurations
- **Best Practices Guidance** - Latest Terraform best practices from HashiCorp
- **Code Generation** - Generate production-ready Terraform configurations
- **Error Diagnosis** - Identify and fix Terraform issues
- **Security Analysis** - Security best practices and recommendations
- **Cost Optimization** - Suggestions for infrastructure cost optimization

### 📚 **Latest Documentation Integration**
- **Current as of 2024-06-22** - References latest Terraform documentation
- **HashiCorp Official** - Based on [https://developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform)
- **Best Practices** - Incorporates official HashiCorp recommendations

### 🛠️ **Advanced Workflows**
- **Code Review Mode** - Comprehensive analysis with suggestions
- **Interactive Mode** - Conversational AI assistant
- **Validation Mode** - Syntax and best practices validation
- **Approval Workflows** - Review changes before applying
- **Backup & Recovery** - Automatic backups before modifications

## 🚀 Quick Start

### Prerequisites
- Python 3.9+
- Ollama with `codellama:7b-instruct` model
- Terraform files to work with

### Installation

1. **Clone the repository:**
```bash
git clone <repository-url>
cd x-terraform
```

2. **Install dependencies:**
```bash
pip install -r requirements.txt
```

3. **Install and start Ollama:**
```bash
# macOS
brew install ollama
brew services start ollama

# Download the model
ollama pull codellama:7b-instruct
```

4. **Set up environment:**
```bash
cp config/default.env .env
# Edit .env with your preferences
```

### Basic Usage

#### Interactive Mode
```bash
python -m agent.main --interactive --dir workspace
```

#### Analyze Terraform Files
```bash
python -m agent.main --dir workspace --analyze
```

#### Code Review
```bash
python -m agent.main --dir workspace --review
```

#### Validate Configuration
```bash
python -m agent.main --dir workspace --validate
```

#### Ask Questions
```bash
python -m agent.main --dir workspace "What does this Terraform code do?"
```

## 📋 Command Reference

### Core Commands

| Command | Description |
|---------|-------------|
| `--interactive` | Start interactive AI assistant |
| `--dir <path>` | Set working directory (no git required) |
| `--analyze` | Analyze Terraform files |
| `--review` | Review code and provide suggestions |
| `--validate` | Validate Terraform configurations |
| `--status` | Show agent status and capabilities |

### Examples

```bash
# Analyze a local directory
python -m agent.main --dir ./my-terraform --analyze

# Review code with suggestions
python -m agent.main --dir ./my-terraform --review

# Ask specific questions
python -m agent.main --dir ./my-terraform "How can I optimize this VPC configuration?"

# Interactive mode with specific directory
python -m agent.main --interactive --dir ./my-terraform
```

## 🏗️ Architecture

### Components

- **Agent Core** (`agent/core/`) - Main agent logic and orchestration
- **Terraform Parser** (`agent/terraform/`) - Terraform file parsing and analysis
- **Ollama Client** (`agent/models/`) - Local AI model integration
- **Git Integration** (`agent/git/`) - Optional Git repository support
- **CLI Interface** (`agent/main.py`) - Command-line interface

### Key Features

1. **Local File Processing**
   - Reads Terraform files directly from local directories
   - No Git repository requirement
   - Supports `.tf`, `.tfvars`, and `.hcl` files

2. **AI-Powered Analysis**
   - Uses local Ollama models for analysis
   - Provides intelligent suggestions and reviews
   - Generates code improvements

3. **Approval Workflows**
   - Shows proposed changes before applying
   - Creates automatic backups
   - Requires user confirmation for modifications

4. **Comprehensive Validation**
   - Syntax validation
   - Best practices checking
   - Security analysis
   - Cost optimization suggestions

## 🔧 Configuration

### Environment Variables

Create a `.env` file with your preferences:

```env
# Agent Configuration
AGENT_MODEL=codellama:7b-instruct
AGENT_TEMPERATURE=0.7
AGENT_MAX_TOKENS=2048
AGENT_REQUIRE_APPROVAL=true

# Ollama Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_TIMEOUT=30

# Logging
LOG_LEVEL=INFO
```

### Model Requirements

- **Recommended Model**: `codellama:7b-instruct`
- **Size**: ~3.8GB
- **Performance**: Optimized for code analysis and generation
- **Offline**: Works without internet connection

## 📊 Capabilities

### Code Analysis
- ✅ Resource identification and analysis
- ✅ Provider configuration review
- ✅ Variable and output analysis
- ✅ Module usage analysis
- ✅ Dependency mapping

### Code Review
- ✅ Security best practices
- ✅ Performance optimization
- ✅ Cost optimization
- ✅ Naming conventions
- ✅ Documentation quality

### Code Generation
- ✅ Resource creation
- ✅ Module templates
- ✅ Best practice implementations
- ✅ Security-focused configurations

### Validation
- ✅ Syntax validation
- ✅ Configuration validation
- ✅ Best practices validation
- ✅ Security validation

## 🔒 Security & Best Practices

### Security Features
- **Local Processing** - No data sent to external services
- **Approval Workflows** - User confirmation for all changes
- **Backup Creation** - Automatic backups before modifications
- **Security Analysis** - Built-in security best practices checking

### Best Practices Integration
- **HashiCorp Official** - Based on official Terraform documentation
- **Latest Standards** - Current as of 2024-06-22
- **Community Guidelines** - Incorporates community best practices

## 🚀 Advanced Usage

### Code Review Workflow

1. **Review Code:**
```bash
python -m agent.main --dir ./my-terraform --review
```

2. **Apply Suggestions:**
```bash
# The agent will show proposed changes and ask for approval
```

3. **Validate Changes:**
```bash
python -m agent.main --dir ./my-terraform --validate
```

### Interactive Development

```bash
python -m agent.main --interactive --dir ./my-terraform
```

Example conversation:
```
> What does this VPC configuration do?
> How can I improve the security?
> Generate a more cost-effective version
> Review the entire configuration
```

## 📈 Performance

### Model Performance
- **Response Time**: 2-30 seconds depending on complexity
- **Memory Usage**: ~4GB RAM for model
- **CPU Usage**: Moderate during inference
- **Accuracy**: High for Terraform-specific tasks

### Optimization Tips
- Use SSD storage for faster model loading
- Ensure adequate RAM (8GB+ recommended)
- Close other applications during heavy usage

## 🤝 Contributing

### Development Setup

1. **Clone and setup:**
```bash
git clone <repository-url>
cd x-terraform
pip install -e .
```

2. **Run tests:**
```bash
python -m pytest tests/
```

3. **Development mode:**
```bash
python -m agent.main --interactive --dir workspace --verbose
```

### Code Style
- Follow PEP 8 guidelines
- Use type hints
- Include docstrings
- Write tests for new features

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **HashiCorp** - For Terraform and official documentation
- **Ollama** - For local AI model capabilities
- **Terraform Community** - For best practices and guidance

## 📞 Support

### Documentation
- **Terraform Docs**: [https://developer.hashicorp.com/terraform](https://developer.hashicorp.com/terraform)
- **Ollama Docs**: [https://ollama.ai/docs](https://ollama.ai/docs)

### Issues
- Report bugs via GitHub Issues
- Feature requests welcome
- Community contributions appreciated

---

**X-Terraform Agent v0.0.1** - Making Terraform development smarter, faster, and more secure with AI-powered assistance.

*Built with ❤️ for the Terraform community* 