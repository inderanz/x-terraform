#!/bin/bash

# X-Terraform Agent Installation Script
# Version: 0.0.1
# Description: Complete installation script for X-Terraform Agent

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$SCRIPT_DIR"
VENV_DIR="$AGENT_DIR/venv"
OLLAMA_DIR="$HOME/.ollama"
MODEL_NAME="codellama:7b-instruct"
PYTHON_VERSION="3.9"
MIN_RAM_GB=8
MIN_DISK_GB=10

# Logging
LOG_FILE="$AGENT_DIR/logs/install-$(date +%Y%m%d-%H%M%S).log"

# Create logs directory if it doesn't exist
mkdir -p "$AGENT_DIR/logs"

log() {
    echo -e "$1" | tee -a "$LOG_FILE"
}

print_header() {
    log "${BLUE}========================================${NC}"
    log "${BLUE}$1${NC}"
    log "${BLUE}========================================${NC}"
}

print_success() {
    log "${GREEN}✓ $1${NC}"
}

print_warning() {
    log "${YELLOW}⚠ $1${NC}"
}

print_error() {
    log "${RED}✗ $1${NC}"
}

print_info() {
    log "${BLUE}ℹ $1${NC}"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Detect operating system
detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command_exists apt-get; then
            echo "ubuntu"
        elif command_exists yum; then
            echo "centos"
        elif command_exists dnf; then
            echo "fedora"
        else
            echo "linux"
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
}

# Check system requirements
check_system_requirements() {
    print_header "Checking System Requirements"
    
    local os=$(detect_os)
    print_info "Detected OS: $os"
    
    # Check RAM
    local total_ram_gb=0
    if [[ "$os" == "macos" ]]; then
        total_ram_gb=$(sysctl -n hw.memsize | awk '{print int($1/1024/1024/1024)}')
    else
        total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    fi
    
    print_info "Total RAM: ${total_ram_gb}GB"
    if [ "$total_ram_gb" -lt "$MIN_RAM_GB" ]; then
        print_warning "Recommended RAM: ${MIN_RAM_GB}GB, found: ${total_ram_gb}GB"
        print_warning "Performance may be limited with less RAM"
    else
        print_success "RAM requirement met"
    fi
    
    # Check disk space
    local available_disk_gb=$(df -BG "$AGENT_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    print_info "Available disk space: ${available_disk_gb}GB"
    if [ "$available_disk_gb" -lt "$MIN_DISK_GB" ]; then
        print_error "Insufficient disk space. Required: ${MIN_DISK_GB}GB, available: ${available_disk_gb}GB"
        return 1
    else
        print_success "Disk space requirement met"
    fi
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity available"
    else
        print_error "Internet connectivity required for installation"
        return 1
    fi
}

# Install Python
install_python() {
    print_header "Installing Python $PYTHON_VERSION"
    
    local os=$(detect_os)
    
    if command_exists python3; then
        local current_version=$(python3 --version 2>&1 | cut -d' ' -f2)
        print_info "Python3 is already installed: $current_version"
        
        # Check if version meets requirements
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
            print_success "Python version meets requirements"
            return 0
        else
            print_warning "Python version $current_version is below required version 3.9"
        fi
    fi
    
    print_info "Installing Python $PYTHON_VERSION..."
    
    case "$os" in
        "ubuntu"|"debian")
            sudo apt-get update
            sudo apt-get install -y python3 python3-pip python3-venv python3-dev
            ;;
        "centos"|"rhel")
            sudo yum install -y python3 python3-pip python3-devel
            ;;
        "fedora")
            sudo dnf install -y python3 python3-pip python3-devel
            ;;
        "macos")
            if command_exists brew; then
                brew install python@3.9
            else
                print_error "Homebrew is required for Python installation on macOS"
                print_info "Install Homebrew: https://brew.sh"
                return 1
            fi
            ;;
        *)
            print_error "Unsupported operating system: $os"
            return 1
            ;;
    esac
    
    print_success "Python installation completed"
}

# Create virtual environment
create_virtual_environment() {
    print_header "Creating Virtual Environment"
    
    # Check if we have a pre-installed virtual environment
    if [ -d "$AGENT_DIR/venv" ]; then
        print_info "Found pre-installed virtual environment - using offline dependencies"
        cp -r "$AGENT_DIR/venv" "$VENV_DIR"
        print_success "Pre-installed virtual environment copied (offline mode)"
        return 0
    fi
    
    if [ -d "$VENV_DIR" ]; then
        print_warning "Virtual environment already exists at $VENV_DIR"
        read -p "Remove existing virtual environment? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$VENV_DIR"
            print_info "Removed existing virtual environment"
        else
            print_info "Using existing virtual environment"
            return 0
        fi
    fi
    
    print_info "Creating virtual environment at $VENV_DIR"
    python3 -m venv "$VENV_DIR"
    
    print_success "Virtual environment created"
    print_info "To activate: source $VENV_DIR/bin/activate"
}

# Install Python dependencies
install_python_dependencies() {
    print_header "Installing Python Dependencies"
    
    # Check if we have a pre-installed virtual environment
    if [ -d "$AGENT_DIR/venv" ]; then
        print_info "Using pre-installed virtual environment (offline mode)"
        print_success "Python dependencies already available"
        return 0
    fi
    
    if [ ! -f "$AGENT_DIR/requirements.txt" ]; then
        print_error "requirements.txt not found"
        return 1
    fi
    
    # Activate virtual environment
    source "$VENV_DIR/bin/activate"
    
    print_info "Upgrading pip..."
    pip install --upgrade pip
    
    print_info "Installing dependencies from requirements.txt..."
    pip install -r "$AGENT_DIR/requirements.txt"
    
    print_success "Python dependencies installed"
}

# Install Ollama
install_ollama() {
    print_header "Installing Ollama"
    
    if command_exists ollama; then
        local version=$(ollama --version 2>/dev/null || echo "unknown")
        print_info "Ollama is already installed: $version"
        return 0
    fi
    
    print_info "Installing Ollama..."
    
    # Download and install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh
    
    # Start Ollama service
    print_info "Starting Ollama service..."
    ollama serve >/dev/null 2>&1 &
    
    # Wait for service to start
    sleep 5
    
    if pgrep -f ollama >/dev/null; then
        print_success "Ollama installed and started"
    else
        print_error "Failed to start Ollama service"
        return 1
    fi
}

# Download Ollama model
download_ollama_model() {
    print_header "Setting Up Ollama Model"
    
    print_info "Model: $MODEL_NAME"
    
    # Check if model already exists
    if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
        print_info "Model $MODEL_NAME is already available"
        return 0
    fi
    
    # Check if we have offline model files
    if [ -d "$AGENT_DIR/ollama-model" ]; then
        print_info "Found offline model files - installing locally"
        install_offline_model
    else
        print_info "No offline model files found - downloading from internet"
        print_info "Size: ~3.8GB"
        print_info "This may take several minutes depending on your internet connection..."
        
        # Download model
        print_info "Downloading model..."
        if ollama pull "$MODEL_NAME"; then
            print_success "Model downloaded successfully"
        else
            print_error "Failed to download model"
            return 1
        fi
    fi
}

# Install model from offline files
install_offline_model() {
    print_header "Installing Offline Model"
    
    local ollama_dir="$HOME/.ollama"
    local model_dir="$AGENT_DIR/ollama-model"
    
    print_info "Installing model from offline files..."
    
    # Create Ollama directories if they don't exist
    mkdir -p "$ollama_dir/models/blobs"
    mkdir -p "$ollama_dir/models/manifests/registry.ollama.ai/library/codellama"
    
    # Copy model blobs
    print_info "Copying model blobs..."
    if [ -d "$model_dir/blobs" ]; then
        cp "$model_dir/blobs"/* "$ollama_dir/models/blobs/"
        print_success "Model blobs copied"
    else
        print_error "Model blobs directory not found"
        return 1
    fi
    
    # Copy model manifest
    print_info "Copying model manifest..."
    if [ -f "$model_dir/manifests/registry.ollama.ai/library/codellama/7b-instruct" ]; then
        cp "$model_dir/manifests/registry.ollama.ai/library/codellama/7b-instruct" "$ollama_dir/models/manifests/registry.ollama.ai/library/codellama/"
        print_success "Model manifest copied"
    else
        print_error "Model manifest not found"
        return 1
    fi
    
    # Verify model installation
    print_info "Verifying model installation..."
    if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
        print_success "Model installed successfully from offline files"
    else
        print_warning "Model not detected in ollama list - may need to restart Ollama service"
        print_info "Restarting Ollama service..."
        pkill -f ollama || true
        sleep 2
        ollama serve >/dev/null 2>&1 &
        sleep 5
        
        if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
            print_success "Model verified after service restart"
        else
            print_error "Model installation verification failed"
            return 1
        fi
    fi
}

# Setup agent configuration
setup_configuration() {
    print_header "Setting Up Configuration"
    
    # Create config directory if it doesn't exist
    mkdir -p "$AGENT_DIR/config"
    
    # Create default environment file if it doesn't exist
    if [ ! -f "$AGENT_DIR/config/default.env" ]; then
        cat > "$AGENT_DIR/config/default.env" << EOF
# X-Terraform Agent Configuration
# Version: 0.0.1

# Ollama Configuration
OLLAMA_HOST=localhost
OLLAMA_PORT=11434
MODEL_NAME=codellama:7b-instruct

# Agent Configuration
AGENT_LOG_LEVEL=INFO
AGENT_MAX_TOKENS=4096
AGENT_TEMPERATURE=0.7

# Terraform Configuration
TERRAFORM_VERSION=latest
TERRAFORM_DOCS_URL=https://developer.hashicorp.com/terraform

# Git Configuration
GIT_ENABLED=true
GIT_AUTO_COMMIT=false
GIT_BRANCH_PREFIX=agent/

# Output Configuration
OUTPUT_FORMAT=markdown
OUTPUT_SAVE_TO_FILE=true
OUTPUT_DIR=./output
EOF
        print_success "Created default configuration file"
    else
        print_info "Configuration file already exists"
    fi
}

# Make scripts executable
make_scripts_executable() {
    print_header "Setting Up Scripts"
    
    local scripts=(
        "scripts/agent-cli.sh"
        "scripts/setup.sh"
        "scripts/init-agent.sh"
        "scripts/health-check.sh"
    )
    
    for script in "${scripts[@]}"; do
        if [ -f "$AGENT_DIR/$script" ]; then
            chmod +x "$AGENT_DIR/$script"
            print_success "Made $script executable"
        else
            print_warning "Script not found: $script"
        fi
    done
}

# Create desktop shortcuts (Linux)
create_desktop_shortcuts() {
    local os=$(detect_os)
    
    if [[ "$os" == "linux" ]]; then
        print_header "Creating Desktop Shortcuts"
        
        local desktop_dir="$HOME/Desktop"
        if [ -d "$desktop_dir" ]; then
            # Create desktop entry for agent CLI
            cat > "$desktop_dir/x-terraform-agent.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=X-Terraform Agent
Comment=AI-powered Terraform development assistant
Exec=$AGENT_DIR/scripts/agent-cli.sh
Icon=terminal
Terminal=true
Categories=Development;
EOF
            chmod +x "$desktop_dir/x-terraform-agent.desktop"
            print_success "Created desktop shortcut"
        fi
    fi
}

# Run health check
run_health_check() {
    print_header "Running Health Check"
    
    if [ -f "$AGENT_DIR/scripts/health-check.sh" ]; then
        print_info "Running comprehensive health check..."
        if "$AGENT_DIR/scripts/health-check.sh" --quick; then
            print_success "Health check passed"
        else
            print_warning "Health check completed with warnings"
            print_info "Review the health check log for details"
        fi
    else
        print_warning "Health check script not found"
    fi
}

# Display completion message
display_completion() {
    print_header "Installation Completed Successfully"
    
    log ""
    log "${GREEN}🎉 X-Terraform Agent v0.0.1 is now installed!${NC}"
    log ""
    log "Next Steps:"
    log "1. Activate the virtual environment:"
    log "   ${BLUE}source $VENV_DIR/bin/activate${NC}"
    log ""
    log "2. Run the agent:"
    log "   ${BLUE}$AGENT_DIR/scripts/agent-cli.sh${NC}"
    log ""
    log "3. Get help:"
    log "   ${BLUE}$AGENT_DIR/scripts/agent-cli.sh --help${NC}"
    log ""
    log "4. Run health check:"
    log "   ${BLUE}$AGENT_DIR/scripts/health-check.sh${NC}"
    log ""
    log "Documentation:"
    log "- Quick Start: ${BLUE}$AGENT_DIR/docs/QUICKSTART.md${NC}"
    log "- User Guide: ${BLUE}$AGENT_DIR/docs/README.md${NC}"
    log "- Examples: ${BLUE}$AGENT_DIR/examples/${NC}"
    log ""
    log "Log file: ${BLUE}$LOG_FILE${NC}"
    log ""
    log "Happy Terraforming! 🚀"
}

# Main installation function
main() {
    print_header "X-Terraform Agent Installation v0.0.1"
    
    log "Installation started at: $(date)"
    log "Installation directory: $AGENT_DIR"
    log ""
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_warning "Running as root is not recommended"
        read -p "Continue anyway? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
    
    # Run installation steps
    check_system_requirements || exit 1
    install_python || exit 1
    create_virtual_environment || exit 1
    install_python_dependencies || exit 1
    install_ollama || exit 1
    download_ollama_model || exit 1
    setup_configuration || exit 1
    make_scripts_executable || exit 1
    create_desktop_shortcuts
    run_health_check
    
    # Display completion message
    display_completion
    
    log ""
    log "Installation completed at: $(date)"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verbose, -v  Enable verbose output"
        echo "  --skip-model   Skip model download (for testing)"
        echo "  --force        Force reinstallation"
        echo ""
        echo "This script installs the complete X-Terraform Agent environment."
        echo "It will install Python 3.9+, Ollama, and the codellama:7b-instruct model."
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
    --skip-model)
        SKIP_MODEL=true
        ;;
    --force)
        FORCE_INSTALL=true
        ;;
esac

# Run main function
main "$@" 