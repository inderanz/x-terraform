#!/bin/bash
# Linux-specific installation script
# This script handles Linux-specific installation requirements

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

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Detect Linux distribution
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    elif command -v apt-get >/dev/null 2>&1; then
        echo "ubuntu"
    elif command -v yum >/dev/null 2>&1; then
        echo "centos"
    elif command -v dnf >/dev/null 2>&1; then
        echo "fedora"
    else
        echo "unknown"
    fi
}

# Install system dependencies
install_system_dependencies() {
    print_header "Installing System Dependencies"
    
    local distro=$(detect_distro)
    print_info "Detected distribution: $distro"
    
    case "$distro" in
        "ubuntu"|"debian")
            print_info "Installing dependencies for Ubuntu/Debian..."
            sudo apt-get update
            sudo apt-get install -y \
                python3 \
                python3-pip \
                python3-venv \
                python3-dev \
                build-essential \
                curl \
                wget \
                git \
                ca-certificates \
                gnupg \
                lsb-release
            ;;
        "centos"|"rhel"|"rocky"|"almalinux")
            print_info "Installing dependencies for CentOS/RHEL..."
            sudo yum update -y
            sudo yum install -y \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                make \
                curl \
                wget \
                git \
                ca-certificates \
                gnupg2
            ;;
        "fedora")
            print_info "Installing dependencies for Fedora..."
            sudo dnf update -y
            sudo dnf install -y \
                python3 \
                python3-pip \
                python3-devel \
                gcc \
                gcc-c++ \
                make \
                curl \
                wget \
                git \
                ca-certificates \
                gnupg2
            ;;
        *)
            print_warning "Unknown distribution: $distro"
            print_info "Please install the following packages manually:"
            print_info "- python3, python3-pip, python3-venv, python3-dev"
            print_info "- build-essential (or gcc, gcc-c++, make)"
            print_info "- curl, wget, git, ca-certificates"
            ;;
    esac
    
    print_success "System dependencies installed"
}

# Install Ollama for Linux
install_ollama() {
    print_header "Installing Ollama"
    
    if command -v ollama >/dev/null 2>&1; then
        print_info "Ollama is already installed"
        return 0
    fi
    
    print_info "Installing Ollama..."
    
    # Download and install Ollama
    curl -fsSL https://ollama.ai/install.sh | sh
    
    # Start Ollama service
    if command -v systemctl >/dev/null 2>&1; then
        sudo systemctl enable ollama
        sudo systemctl start ollama
    else
        print_warning "systemctl not available, starting Ollama manually"
        ollama serve &
    fi
    
    print_success "Ollama installed and started"
}

# Main installation function
main() {
    print_header "Linux Installation Setup"
    
    # Install system dependencies
    install_system_dependencies
    
    # Install Ollama
    install_ollama
    
    # Run main installation script
    print_info "Running main installation script..."
    ./install.sh "$@"
    
    print_success "Linux installation completed!"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verbose, -v  Enable verbose output"
        echo "  --skip-deps    Skip system dependencies installation"
        echo ""
        echo "This script handles Linux-specific installation requirements."
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
    --skip-deps)
        print_info "Skipping system dependencies installation"
        ./install.sh "$@"
        exit 0
        ;;
esac

# Run main function
main "$@"
