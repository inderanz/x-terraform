#!/bin/bash

# X-Terraform Agent Uninstall Script
# Version: 0.0.1
# Description: Clean uninstallation of X-Terraform Agent

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

# Logging
LOG_FILE="$AGENT_DIR/logs/uninstall-$(date +%Y%m%d-%H%M%S).log"

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

# Stop Ollama service
stop_ollama_service() {
    print_header "Stopping Ollama Service"
    
    if pgrep -f ollama >/dev/null; then
        print_info "Stopping Ollama service..."
        pkill -f ollama || true
        sleep 3
        
        if pgrep -f ollama >/dev/null; then
            print_warning "Ollama service is still running"
            print_info "You may need to stop it manually"
        else
            print_success "Ollama service stopped"
        fi
    else
        print_info "Ollama service is not running"
    fi
}

# Remove Ollama model
remove_ollama_model() {
    print_header "Removing Ollama Model"
    
    if command_exists ollama; then
        if ollama list 2>/dev/null | grep -q "$MODEL_NAME"; then
            print_info "Removing model: $MODEL_NAME"
            if ollama rm "$MODEL_NAME"; then
                print_success "Model removed successfully"
            else
                print_warning "Failed to remove model"
            fi
        else
            print_info "Model $MODEL_NAME not found"
        fi
    else
        print_info "Ollama not installed"
    fi
}

# Remove Ollama installation
remove_ollama() {
    print_header "Removing Ollama"
    
    local os=$(detect_os)
    
    if command_exists ollama; then
        print_info "Removing Ollama installation..."
        
        case "$os" in
            "ubuntu"|"debian")
                sudo apt-get remove -y ollama || true
                ;;
            "centos"|"rhel")
                sudo yum remove -y ollama || true
                ;;
            "fedora")
                sudo dnf remove -y ollama || true
                ;;
            "macos")
                if command_exists brew; then
                    brew uninstall ollama || true
                fi
                ;;
        esac
        
        # Remove Ollama binary
        if [ -f "/usr/local/bin/ollama" ]; then
            sudo rm -f /usr/local/bin/ollama
        fi
        
        print_success "Ollama removed"
    else
        print_info "Ollama not found"
    fi
}

# Remove Ollama data directory
remove_ollama_data() {
    print_header "Removing Ollama Data"
    
    if [ -d "$OLLAMA_DIR" ]; then
        print_info "Removing Ollama data directory: $OLLAMA_DIR"
        read -p "Remove Ollama data directory? This will delete all models. (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$OLLAMA_DIR"
            print_success "Ollama data directory removed"
        else
            print_info "Keeping Ollama data directory"
        fi
    else
        print_info "Ollama data directory not found"
    fi
}

# Remove virtual environment
remove_virtual_environment() {
    print_header "Removing Virtual Environment"
    
    if [ -d "$VENV_DIR" ]; then
        print_info "Removing virtual environment: $VENV_DIR"
        rm -rf "$VENV_DIR"
        print_success "Virtual environment removed"
    else
        print_info "Virtual environment not found"
    fi
}

# Remove desktop shortcuts
remove_desktop_shortcuts() {
    print_header "Removing Desktop Shortcuts"
    
    local os=$(detect_os)
    
    if [[ "$os" == "linux" ]]; then
        local desktop_dir="$HOME/Desktop"
        local shortcut="$desktop_dir/x-terraform-agent.desktop"
        
        if [ -f "$shortcut" ]; then
            print_info "Removing desktop shortcut: $shortcut"
            rm -f "$shortcut"
            print_success "Desktop shortcut removed"
        else
            print_info "Desktop shortcut not found"
        fi
    fi
}

# Remove logs
remove_logs() {
    print_header "Removing Logs"
    
    if [ -d "$AGENT_DIR/logs" ]; then
        print_info "Removing log directory: $AGENT_DIR/logs"
        rm -rf "$AGENT_DIR/logs"
        print_success "Logs removed"
    else
        print_info "Log directory not found"
    fi
}

# Remove agent files
remove_agent_files() {
    print_header "Removing Agent Files"
    
    print_info "Agent directory: $AGENT_DIR"
    print_warning "This will remove ALL agent files and directories"
    read -p "Remove entire agent directory? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Removing agent directory..."
        cd ..
        rm -rf "$AGENT_DIR"
        print_success "Agent directory removed"
        exit 0
    else
        print_info "Keeping agent directory"
        print_info "You can manually remove it later: rm -rf $AGENT_DIR"
    fi
}

# Clean Python packages (optional)
clean_python_packages() {
    print_header "Cleaning Python Packages"
    
    print_info "This will remove Python packages that may have been installed globally"
    read -p "Remove Python packages? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        local packages=(
            "requests"
            "python-dotenv"
            "colorama"
            "rich"
            "typer"
        )
        
        for package in "${packages[@]}"; do
            if python3 -c "import $package" 2>/dev/null; then
                print_info "Removing package: $package"
                pip3 uninstall -y "$package" || true
            fi
        done
        
        print_success "Python packages cleaned"
    else
        print_info "Keeping Python packages"
    fi
}

# Display uninstall summary
display_summary() {
    print_header "Uninstall Summary"
    
    log ""
    log "The following components have been removed:"
    log "✓ Ollama service stopped"
    log "✓ Ollama model removed"
    log "✓ Ollama installation removed"
    log "✓ Virtual environment removed"
    log "✓ Desktop shortcuts removed"
    log "✓ Log files removed"
    log ""
    
    if [ -d "$AGENT_DIR" ]; then
        log "Note: Agent directory still exists at: $AGENT_DIR"
        log "To remove it completely, run: rm -rf $AGENT_DIR"
    fi
    
    log ""
    log "Uninstall completed at: $(date)"
    log "Log file: $LOG_FILE"
}

# Main uninstall function
main() {
    print_header "X-Terraform Agent Uninstall v0.0.1"
    
    log "Uninstall started at: $(date)"
    log "Agent directory: $AGENT_DIR"
    log ""
    
    # Confirm uninstall
    print_warning "This will remove the X-Terraform Agent and all its components"
    print_warning "This action cannot be undone"
    read -p "Continue with uninstall? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstall cancelled"
        exit 0
    fi
    
    # Run uninstall steps
    stop_ollama_service
    remove_ollama_model
    remove_ollama
    remove_ollama_data
    remove_virtual_environment
    remove_desktop_shortcuts
    remove_logs
    clean_python_packages
    remove_agent_files
    
    # Display summary
    display_summary
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verbose, -v  Enable verbose output"
        echo "  --force        Skip confirmation prompts"
        echo "  --keep-data    Keep Ollama data directory"
        echo "  --keep-agent   Keep agent directory"
        echo ""
        echo "This script removes the X-Terraform Agent and all its components."
        echo "It will stop Ollama, remove models, and clean up all files."
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
    --force)
        FORCE_UNINSTALL=true
        ;;
    --keep-data)
        KEEP_DATA=true
        ;;
    --keep-agent)
        KEEP_AGENT=true
        ;;
esac

# Run main function
main "$@" 