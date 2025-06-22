# X-Terraform Agent Installation Guide

## Table of Contents
1. [System Requirements](#system-requirements)
2. [Quick Installation](#quick-installation)
3. [Manual Installation](#manual-installation)
4. [Platform-Specific Instructions](#platform-specific-instructions)
5. [Verification](#verification)
6. [Troubleshooting](#troubleshooting)
7. [Uninstallation](#uninstallation)

## System Requirements

### Minimum Requirements
- **Operating System**: macOS 10.15+ or Linux (Ubuntu 18.04+, CentOS 7+, Fedora 30+)
- **RAM**: 8GB minimum
- **Storage**: 10GB free space
- **CPU**: 4 cores minimum
- **Network**: Stable internet connection

### Recommended Requirements
- **RAM**: 16GB or more
- **Storage**: 20GB free space
- **CPU**: 8 cores or more
- **GPU**: NVIDIA GPU with CUDA support (optional, for faster inference)

### Network Requirements
- Stable internet connection for initial model download (~3.8GB)
- Access to GitHub for code repositories (if using Git features)
- Access to HashiCorp documentation (for best practices)

## Quick Installation

### Automated Installation (Recommended)

The easiest way to install X-Terraform Agent is using the automated installation script:

```bash
# Download and install in one command
curl -fsSL https://storage.googleapis.com/x-terraform-agent/install.sh | bash
```

### Manual Download and Install

If you prefer to download and install manually:

```bash
# 1. Download the package
wget https://storage.googleapis.com/x-terraform-agent/x-terraform-agent-v0.0.1.tar.gz

# 2. Extract the package
tar -xzf x-terraform-agent-v0.0.1.tar.gz

# 3. Navigate to the directory
cd x-terraform-agent-v0.0.1

# 4. Run the installation script
./install.sh
```

## Manual Installation

### Step 1: Install Python 3.9+

#### macOS
```bash
# Using Homebrew (recommended)
brew install python@3.9

# Verify installation
python3 --version
```

#### Ubuntu/Debian
```bash
# Update package list
sudo apt-get update

# Install Python 3.9
sudo apt-get install -y python3 python3-pip python3-venv python3-dev

# Verify installation
python3 --version
```

#### CentOS/RHEL
```bash
# Install Python 3.9
sudo yum install -y python3 python3-pip python3-devel

# Verify installation
python3 --version
```

#### Fedora
```bash
# Install Python 3.9
sudo dnf install -y python3 python3-pip python3-devel

# Verify installation
python3 --version
```

### Step 2: Install Ollama

#### Automated Installation
```bash
# Install Ollama using the official installer
curl -fsSL https://ollama.ai/install.sh | sh
```

#### Manual Installation

##### macOS
```bash
# Using Homebrew
brew install ollama

# Or download from GitHub
curl -L https://github.com/ollama/ollama/releases/latest/download/ollama-darwin-amd64 -o ollama
chmod +x ollama
sudo mv ollama /usr/local/bin/
```

##### Linux
```bash
# Download the latest release
curl -L https://github.com/ollama/ollama/releases/latest/download/ollama-linux-amd64 -o ollama
chmod +x ollama
sudo mv ollama /usr/local/bin/
```

### Step 3: Download the Model

```bash
# Start Ollama service
ollama serve &

# Download the codellama:7b-instruct model
ollama pull codellama:7b-instruct
```

### Step 4: Install X-Terraform Agent

```bash
# Clone or download the agent
git clone <repository-url> x-terraform-agent
cd x-terraform-agent

# Create virtual environment
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Make scripts executable
chmod +x scripts/*.sh
chmod +x install.sh
chmod +x uninstall.sh
```

### Step 5: Configure the Agent

```bash
# Copy default configuration
cp config/default.env config/local.env

# Edit configuration if needed
nano config/local.env
```

## Platform-Specific Instructions

### macOS

#### Prerequisites
- Install Homebrew: https://brew.sh
- Xcode Command Line Tools: `xcode-select --install`

#### Installation
```bash
# Install dependencies
brew install python@3.9 curl wget

# Run installation
./install.sh
```

#### Troubleshooting
- If you get permission errors, ensure Xcode Command Line Tools are installed
- For M1/M2 Macs, ensure you're using the ARM64 version of Python and Ollama

### Linux (Ubuntu/Debian)

#### Prerequisites
```bash
# Update system
sudo apt-get update
sudo apt-get upgrade -y

# Install build essentials
sudo apt-get install -y build-essential curl wget git
```

#### Installation
```bash
# Run installation
./install.sh
```

#### Troubleshooting
- If you get permission errors, ensure your user is in the `sudo` group
- For older Ubuntu versions, you may need to add the deadsnakes PPA for Python 3.9

### Linux (CentOS/RHEL)

#### Prerequisites
```bash
# Install EPEL repository
sudo yum install -y epel-release

# Install development tools
sudo yum groupinstall -y "Development Tools"
```

#### Installation
```bash
# Run installation
./install.sh
```

#### Troubleshooting
- Ensure SELinux is configured properly or disabled
- For RHEL 8+, use `dnf` instead of `yum`

### Linux (Fedora)

#### Prerequisites
```bash
# Install development tools
sudo dnf groupinstall -y "Development Tools"
```

#### Installation
```bash
# Run installation
./install.sh
```

## Verification

### Health Check

Run the comprehensive health check to verify your installation:

```bash
# Run health check
./scripts/health-check.sh

# Run quick health check (skips model test)
./scripts/health-check.sh --quick
```

### Manual Verification

#### Check Python Environment
```bash
# Activate virtual environment
source venv/bin/activate

# Check Python version
python --version

# Check installed packages
pip list
```

#### Check Ollama
```bash
# Check Ollama version
ollama --version

# Check if service is running
pgrep -f ollama

# List available models
ollama list
```

#### Test Agent
```bash
# Activate virtual environment
source venv/bin/activate

# Test agent import
python -c "from agent.main import TerraformAgent; print('Agent imports successfully')"

# Test Ollama client
python -c "from agent.models.ollama_client import OllamaClient; client = OllamaClient(); print('Ollama client works')"
```

#### Test CLI
```bash
# Get help
./scripts/agent-cli.sh --help

# Test basic functionality
./scripts/agent-cli.sh --version
```

## Troubleshooting

### Common Issues

#### 1. Python Version Issues
**Problem**: Python 3.9+ not found
```bash
# Check available Python versions
python3 --version
python3.9 --version
python3.10 --version

# Install specific version if needed
# Ubuntu/Debian
sudo apt-get install python3.9

# macOS
brew install python@3.9
```

#### 2. Ollama Installation Issues
**Problem**: Ollama not found or not working
```bash
# Check if Ollama is installed
which ollama

# Reinstall Ollama
curl -fsSL https://ollama.ai/install.sh | sh

# Start Ollama service
ollama serve &

# Check service status
pgrep -f ollama
```

#### 3. Model Download Issues
**Problem**: Model download fails or is slow
```bash
# Check available disk space
df -h

# Check network connectivity
ping -c 3 8.8.8.8

# Try downloading with verbose output
ollama pull codellama:7b-instruct --verbose

# Check model status
ollama list
```

#### 4. Permission Issues
**Problem**: Permission denied errors
```bash
# Fix script permissions
chmod +x scripts/*.sh
chmod +x install.sh
chmod +x uninstall.sh

# Check directory permissions
ls -la

# Fix ownership if needed
sudo chown -R $USER:$USER .
```

#### 5. Virtual Environment Issues
**Problem**: Virtual environment not working
```bash
# Remove and recreate virtual environment
rm -rf venv
python3 -m venv venv
source venv/bin/activate

# Reinstall dependencies
pip install -r requirements.txt
```

#### 6. Memory Issues
**Problem**: Out of memory errors
```bash
# Check available memory
free -h

# Reduce Ollama memory usage
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_ORIGINS=*

# Restart Ollama with memory limits
pkill -f ollama
ollama serve --memory 4096 &
```

### Performance Optimization

#### For Low-RAM Systems (8GB)
```bash
# Set environment variables for lower memory usage
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_ORIGINS=*

# Start Ollama with memory limits
ollama serve --memory 4096 &
```

#### For High-Performance Systems
```bash
# Use GPU acceleration if available
export OLLAMA_HOST=127.0.0.1:11434
export OLLAMA_ORIGINS=*

# Start with GPU support
ollama serve --gpu &
```

### Network Issues

#### Proxy Configuration
If you're behind a corporate proxy:

```bash
# Set proxy environment variables
export HTTP_PROXY=http://proxy.company.com:8080
export HTTPS_PROXY=http://proxy.company.com:8080
export NO_PROXY=localhost,127.0.0.1

# Configure Git proxy
git config --global http.proxy http://proxy.company.com:8080
git config --global https.proxy http://proxy.company.com:8080
```

#### Firewall Issues
```bash
# Check if ports are blocked
telnet localhost 11434

# Open firewall ports (Ubuntu/Debian)
sudo ufw allow 11434

# Open firewall ports (CentOS/RHEL)
sudo firewall-cmd --permanent --add-port=11434/tcp
sudo firewall-cmd --reload
```

## Uninstallation

### Automated Uninstallation
```bash
# Run the uninstall script
./uninstall.sh
```

### Manual Uninstallation

#### Remove Agent Files
```bash
# Remove agent directory
rm -rf /path/to/x-terraform-agent
```

#### Remove Ollama
```bash
# Stop Ollama service
pkill -f ollama

# Remove Ollama binary
sudo rm -f /usr/local/bin/ollama

# Remove Ollama data (optional)
rm -rf ~/.ollama
```

#### Remove Python Packages
```bash
# Remove virtual environment
rm -rf venv

# Remove global packages (if installed)
pip3 uninstall -y requests python-dotenv colorama rich typer
```

#### Remove Desktop Shortcuts
```bash
# Remove desktop shortcut (Linux)
rm -f ~/Desktop/x-terraform-agent.desktop
```

## Support

### Getting Help

1. **Check the documentation**: Review the docs in the `docs/` directory
2. **Run health check**: Use `./scripts/health-check.sh` to diagnose issues
3. **Check logs**: Review log files in the `logs/` directory
4. **Review examples**: Check the `examples/` directory for usage examples

### Log Files

Log files are stored in the `logs/` directory:
- `install-YYYYMMDD-HHMMSS.log`: Installation logs
- `health-check-YYYYMMDD-HHMMSS.log`: Health check logs
- `agent-YYYYMMDD-HHMMSS.log`: Agent operation logs

### Common Commands

```bash
# Check system status
./scripts/health-check.sh

# Get agent help
./scripts/agent-cli.sh --help

# Check version
./scripts/agent-cli.sh --version

# View logs
tail -f logs/agent-$(date +%Y%m%d).log

# Restart services
pkill -f ollama && ollama serve &
```

## Next Steps

After successful installation:

1. **Read the Quick Start Guide**: `docs/QUICKSTART.md`
2. **Review Examples**: Check the `examples/` directory
3. **Test the Agent**: Try generating a simple Terraform configuration
4. **Explore Features**: Review the comprehensive documentation

Happy Terraforming! 🚀 