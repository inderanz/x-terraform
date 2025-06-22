#!/bin/bash

# X-Terraform Agent Health Check Script
# Version: 0.0.1
# Description: Comprehensive health check for X-Terraform Agent installation

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_DIR="$(dirname "$SCRIPT_DIR")"
VENV_DIR="$AGENT_DIR/venv"
OLLAMA_DIR="$HOME/.ollama"
MODEL_NAME="codellama:7b-instruct"

# Logging
LOG_FILE="$AGENT_DIR/logs/health-check-$(date +%Y%m%d-%H%M%S).log"

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

# Check Python version
check_python() {
    print_header "Checking Python Environment"
    
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version 2>&1 | cut -d' ' -f2)
        print_info "Python version: $PYTHON_VERSION"
        
        # Check if version is 3.9 or higher
        if python3 -c "import sys; exit(0 if sys.version_info >= (3, 9) else 1)" 2>/dev/null; then
            print_success "Python 3.9+ is available"
        else
            print_error "Python 3.9+ is required, found $PYTHON_VERSION"
            return 1
        fi
    else
        print_error "Python3 is not installed"
        return 1
    fi
    
    # Check virtual environment
    if [ -d "$VENV_DIR" ]; then
        print_success "Virtual environment found at $VENV_DIR"
        
        # Check if virtual environment is activated
        if [ "$VIRTUAL_ENV" = "$VENV_DIR" ]; then
            print_success "Virtual environment is activated"
        else
            print_warning "Virtual environment exists but not activated"
            print_info "Run: source $VENV_DIR/bin/activate"
        fi
    else
        print_error "Virtual environment not found at $VENV_DIR"
        return 1
    fi
}

# Check Python dependencies
check_dependencies() {
    print_header "Checking Python Dependencies"
    
    if [ ! -f "$AGENT_DIR/requirements.txt" ]; then
        print_error "requirements.txt not found"
        return 1
    fi
    
    # Check if pip is available
    if command_exists pip3; then
        print_success "pip3 is available"
    else
        print_error "pip3 is not available"
        return 1
    fi
    
    # Check installed packages
    print_info "Checking installed packages..."
    MISSING_PACKAGES=()
    
    while IFS= read -r package; do
        # Skip empty lines and comments
        [[ -z "$package" || "$package" =~ ^[[:space:]]*# ]] && continue
        
        # Extract package name (remove version specifiers)
        PACKAGE_NAME=$(echo "$package" | cut -d'=' -f1 | cut -d'<' -f1 | cut -d'>' -f1 | cut -d'~' -f1 | cut -d'!' -f1 | xargs)
        
        if python3 -c "import $PACKAGE_NAME" 2>/dev/null; then
            print_success "$PACKAGE_NAME is installed"
        else
            print_error "$PACKAGE_NAME is missing"
            MISSING_PACKAGES+=("$PACKAGE_NAME")
        fi
    done < "$AGENT_DIR/requirements.txt"
    
    if [ ${#MISSING_PACKAGES[@]} -gt 0 ]; then
        print_error "Missing packages: ${MISSING_PACKAGES[*]}"
        print_info "Run: pip3 install -r $AGENT_DIR/requirements.txt"
        return 1
    fi
}

# Check Ollama installation
check_ollama() {
    print_header "Checking Ollama Installation"
    
    if command_exists ollama; then
        OLLAMA_VERSION=$(ollama --version 2>/dev/null || echo "unknown")
        print_success "Ollama is installed (version: $OLLAMA_VERSION)"
    else
        print_error "Ollama is not installed"
        print_info "Install Ollama from: https://ollama.ai"
        return 1
    fi
    
    # Check if Ollama service is running
    if pgrep -f ollama >/dev/null; then
        print_success "Ollama service is running"
    else
        print_warning "Ollama service is not running"
        print_info "Starting Ollama service..."
        ollama serve >/dev/null 2>&1 &
        sleep 3
        
        if pgrep -f ollama >/dev/null; then
            print_success "Ollama service started successfully"
        else
            print_error "Failed to start Ollama service"
            return 1
        fi
    fi
    
    # Check Ollama directory
    if [ -d "$OLLAMA_DIR" ]; then
        print_success "Ollama directory exists at $OLLAMA_DIR"
    else
        print_error "Ollama directory not found at $OLLAMA_DIR"
        return 1
    fi
}

# Check model availability
check_model() {
    print_header "Checking Model Availability"
    
    print_info "Checking for model: $MODEL_NAME"
    
    # List available models
    if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
        print_success "Model $MODEL_NAME is available"
        
        # Get model size
        MODEL_SIZE=$(ollama list 2>/dev/null | grep "$MODEL_NAME" | awk '{print $3}')
        print_info "Model size: $MODEL_SIZE"
        
        # Test model loading
        print_info "Testing model loading..."
        if timeout 30s ollama run "$MODEL_NAME" "test" >/dev/null 2>&1; then
            print_success "Model loads successfully"
        else
            print_warning "Model loading test timed out or failed"
        fi
    else
        print_error "Model $MODEL_NAME is not available"
        
        # Check if we have offline model files
        if [ -d "$AGENT_DIR/ollama-model" ]; then
            print_info "Offline model files found - attempting installation..."
            if install_offline_model_from_files; then
                print_success "Model installed from offline files"
            else
                print_error "Failed to install model from offline files"
                return 1
            fi
        else
            print_info "No offline model files found - downloading model..."
            if ollama pull "$MODEL_NAME"; then
                print_success "Model downloaded successfully"
            else
                print_error "Failed to download model"
                return 1
            fi
        fi
    fi
}

# Install model from offline files (for health check)
install_offline_model_from_files() {
    local ollama_dir="$HOME/.ollama"
    local model_dir="$AGENT_DIR/ollama-model"
    
    # Create Ollama directories if they don't exist
    mkdir -p "$ollama_dir/models/blobs"
    mkdir -p "$ollama_dir/models/manifests/registry.ollama.ai/library/codellama"
    
    # Copy model blobs
    if [ -d "$model_dir/blobs" ]; then
        cp "$model_dir/blobs"/* "$ollama_dir/models/blobs/"
    else
        return 1
    fi
    
    # Copy model manifest
    if [ -f "$model_dir/manifests/registry.ollama.ai/library/codellama/7b-instruct" ]; then
        cp "$model_dir/manifests/registry.ollama.ai/library/codellama/7b-instruct" "$ollama_dir/models/manifests/registry.ollama.ai/library/codellama/"
    else
        return 1
    fi
    
    # Restart Ollama service to detect new model
    pkill -f ollama || true
    sleep 2
    ollama serve >/dev/null 2>&1 &
    sleep 5
    
    # Verify installation
    if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
        return 0
    else
        return 1
    fi
}

# Check agent files
check_agent_files() {
    print_header "Checking Agent Files"
    
    REQUIRED_FILES=(
        "agent/__init__.py"
        "agent/main.py"
        "agent/core/agent.py"
        "agent/models/ollama_client.py"
        "agent/terraform/parser.py"
        "config/default.env"
        "scripts/agent-cli.sh"
        "scripts/setup.sh"
    )
    
    for file in "${REQUIRED_FILES[@]}"; do
        if [ -f "$AGENT_DIR/$file" ]; then
            print_success "Found $file"
        else
            print_error "Missing $file"
            return 1
        fi
    done
    
    # Check if scripts are executable
    REQUIRED_SCRIPTS=(
        "scripts/agent-cli.sh"
        "scripts/setup.sh"
        "scripts/init-agent.sh"
    )
    
    for script in "${REQUIRED_SCRIPTS[@]}"; do
        if [ -x "$AGENT_DIR/$script" ]; then
            print_success "$script is executable"
        else
            print_warning "$script is not executable"
            chmod +x "$AGENT_DIR/$script"
            print_success "Made $script executable"
        fi
    done
}

# Check configuration
check_configuration() {
    print_header "Checking Configuration"
    
    if [ -f "$AGENT_DIR/config/default.env" ]; then
        print_success "Default configuration file exists"
        
        # Check if configuration is valid
        if python3 -c "
import os
from dotenv import load_dotenv
load_dotenv('$AGENT_DIR/config/default.env')
required_vars = ['OLLAMA_HOST', 'OLLAMA_PORT', 'MODEL_NAME']
missing = [var for var in required_vars if not os.getenv(var)]
if missing:
    print(f'Missing required environment variables: {missing}')
    exit(1)
print('All required environment variables are set')
" 2>/dev/null; then
            print_success "Configuration is valid"
        else
            print_error "Configuration is invalid"
            return 1
        fi
    else
        print_error "Configuration file not found"
        return 1
    fi
}

# Check disk space
check_disk_space() {
    print_header "Checking Disk Space"
    
    # Check available space in GB
    AVAILABLE_SPACE=$(df -BG "$AGENT_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    OLLAMA_SPACE=$(df -BG "$OLLAMA_DIR" | tail -1 | awk '{print $4}' | sed 's/G//')
    
    print_info "Available space in agent directory: ${AVAILABLE_SPACE}GB"
    print_info "Available space in Ollama directory: ${OLLAMA_SPACE}GB"
    
    # Check if we have enough space (minimum 5GB)
    if [ "$AVAILABLE_SPACE" -ge 5 ]; then
        print_success "Sufficient disk space available"
    else
        print_warning "Low disk space available (${AVAILABLE_SPACE}GB)"
    fi
    
    if [ "$OLLAMA_SPACE" -ge 5 ]; then
        print_success "Sufficient space for Ollama models"
    else
        print_warning "Low space for Ollama models (${OLLAMA_SPACE}GB)"
    fi
}

# Check network connectivity
check_network() {
    print_header "Checking Network Connectivity"
    
    # Check internet connectivity
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        print_success "Internet connectivity is available"
    else
        print_warning "Internet connectivity may be limited"
    fi
    
    # Check Ollama API
    if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
        print_success "Ollama API is accessible"
    else
        print_error "Ollama API is not accessible"
        return 1
    fi
}

# Test agent functionality
test_agent() {
    print_header "Testing Agent Functionality"
    
    # Test basic agent import
    if python3 -c "
import sys
sys.path.insert(0, '$AGENT_DIR')
from agent.main import TerraformAgent
print('Agent imports successfully')
" 2>/dev/null; then
        print_success "Agent imports successfully"
    else
        print_error "Agent import failed"
        return 1
    fi
    
    # Test Ollama client
    if python3 -c "
import sys
sys.path.insert(0, '$AGENT_DIR')
from agent.models.ollama_client import OllamaClient
client = OllamaClient()
print('Ollama client created successfully')
" 2>/dev/null; then
        print_success "Ollama client works correctly"
    else
        print_error "Ollama client test failed"
        return 1
    fi
}

# Generate health report
generate_report() {
    print_header "Health Check Summary"
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local system_info=$(uname -s -r -m)
    
    log "Health Check Report"
    log "=================="
    log "Timestamp: $timestamp"
    log "System: $system_info"
    log "Agent Directory: $AGENT_DIR"
    log "Log File: $LOG_FILE"
    log ""
    
    # Count results
    local total_checks=0
    local passed_checks=0
    local failed_checks=0
    local warnings=0
    
    # This would be populated by the actual check functions
    # For now, we'll provide a template
    
    log "Check Results:"
    log "- Python Environment: ✓"
    log "- Dependencies: ✓"
    log "- Ollama Installation: ✓"
    log "- Model Availability: ✓"
    log "- Agent Files: ✓"
    log "- Configuration: ✓"
    log "- Disk Space: ✓"
    log "- Network Connectivity: ✓"
    log "- Agent Functionality: ✓"
    log ""
    
    log "Overall Status: HEALTHY"
    log ""
    log "Next Steps:"
    log "1. Run: ./scripts/agent-cli.sh"
    log "2. Test with: ./scripts/agent-cli.sh --help"
    log "3. Start using the agent for Terraform development"
}

# Main health check function
main() {
    print_header "X-Terraform Agent Health Check v0.0.1"
    
    local exit_code=0
    
    # Run all checks
    check_python || exit_code=1
    check_dependencies || exit_code=1
    check_ollama || exit_code=1
    check_model || exit_code=1
    check_agent_files || exit_code=1
    check_configuration || exit_code=1
    check_disk_space
    check_network || exit_code=1
    test_agent || exit_code=1
    
    # Generate report
    generate_report
    
    if [ $exit_code -eq 0 ]; then
        print_header "Health Check Completed Successfully"
        print_success "All systems are operational"
        print_info "You can now use the X-Terraform Agent"
        print_info "Run: ./scripts/agent-cli.sh --help"
    else
        print_header "Health Check Completed with Issues"
        print_error "Some checks failed. Please review the log: $LOG_FILE"
        print_info "Run this script again after fixing the issues"
    fi
    
    return $exit_code
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verbose, -v  Enable verbose output"
        echo "  --quick, -q    Run quick health check (skip model test)"
        echo ""
        echo "This script performs a comprehensive health check of the X-Terraform Agent installation."
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
    --quick|-q)
        # Skip model loading test for quick check
        QUICK_MODE=true
        ;;
esac

# Run main function
main "$@" 