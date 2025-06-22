#!/bin/bash
# Linux-specific start script for X-Terraform Agent

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Check if Ollama is running
check_ollama() {
    if ! pgrep -x "ollama" > /dev/null; then
        print_info "Starting Ollama..."
        if command -v systemctl >/dev/null 2>&1; then
            sudo systemctl start ollama
        else
            ollama serve &
            sleep 5
        fi
    fi
    
    # Wait for Ollama to be ready
    local max_attempts=30
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        if curl -s http://localhost:11434/api/tags >/dev/null 2>&1; then
            print_success "Ollama is ready"
            return 0
        fi
        
        print_info "Waiting for Ollama to be ready... (attempt $attempt/$max_attempts)"
        sleep 2
        attempt=$((attempt + 1))
    done
    
    print_error "Ollama failed to start within expected time"
    return 1
}

# Activate virtual environment
activate_venv() {
    if [ -f "venv/bin/activate" ]; then
        source venv/bin/activate
        print_success "Virtual environment activated"
    else
        print_error "Virtual environment not found. Please run install-linux.sh first"
        exit 1
    fi
}

# Main function
main() {
    print_header "X-Terraform Agent - Linux"
    
    # Check if Ollama is running
    check_ollama
    
    # Activate virtual environment
    activate_venv
    
    # Start the agent
    print_info "Starting X-Terraform Agent..."
    python -m agent.main --interactive
}

# Run main function
main "$@"
