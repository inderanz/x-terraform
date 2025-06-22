#!/bin/bash
# Linux-specific health check for X-Terraform Agent

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

# Check system requirements
check_system_requirements() {
    print_header "System Requirements Check"
    
    # Check RAM
    local total_ram_gb=$(free -g | awk '/^Mem:/{print $2}')
    print_info "Total RAM: ${total_ram_gb}GB"
    
    if [ "$total_ram_gb" -lt 8 ]; then
        print_warning "Recommended RAM: 8GB, found: ${total_ram_gb}GB"
    else
        print_success "RAM requirement met"
    fi
    
    # Check disk space
    local available_disk_gb=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    print_info "Available disk space: ${available_disk_gb}GB"
    
    if [ "$available_disk_gb" -lt 10 ]; then
        print_warning "Recommended disk space: 10GB, available: ${available_disk_gb}GB"
    else
        print_success "Disk space requirement met"
    fi
    
    # Check Python
    if command -v python3 >/dev/null 2>&1; then
        local python_version=$(python3 --version 2>&1)
        print_success "Python: $python_version"
    else
        print_error "Python3 not found"
        return 1
    fi
}

# Check Ollama
check_ollama() {
    print_header "Ollama Check"
    
    if command -v ollama >/dev/null 2>&1; then
        print_success "Ollama is installed"
        
        # Check if Ollama is running
        if pgrep -x "ollama" > /dev/null; then
            print_success "Ollama is running"
            
            # Check if model is available
            if ollama list | grep -q "codellama:7b-instruct"; then
                print_success "codellama:7b-instruct model is available"
            else
                print_warning "codellama:7b-instruct model not found"
                print_info "Run: ollama pull codellama:7b-instruct"
            fi
        else
            print_warning "Ollama is not running"
            print_info "Start with: sudo systemctl start ollama"
        fi
    else
        print_error "Ollama not found"
        print_info "Install with: curl -fsSL https://ollama.ai/install.sh | sh"
        return 1
    fi
}

# Check virtual environment
check_venv() {
    print_header "Virtual Environment Check"
    
    if [ -d "venv" ]; then
        print_success "Virtual environment exists"
        
        if [ -f "venv/bin/activate" ]; then
            print_success "Virtual environment is valid"
        else
            print_error "Virtual environment is corrupted"
            return 1
        fi
    else
        print_error "Virtual environment not found"
        print_info "Run: ./install-linux.sh"
        return 1
    fi
}

# Check agent files
check_agent_files() {
    print_header "Agent Files Check"
    
    local required_files=("agent" "config" "docs" "scripts" "requirements.txt")
    local missing_files=()
    
    for file in "${required_files[@]}"; do
        if [ -e "$file" ]; then
            print_success "$file exists"
        else
            print_error "$file missing"
            missing_files+=("$file")
        fi
    done
    
    if [ ${#missing_files[@]} -gt 0 ]; then
        print_error "Missing required files: ${missing_files[*]}"
        return 1
    fi
}

# Main function
main() {
    print_header "X-Terraform Agent Health Check - Linux"
    
    local exit_code=0
    
    check_system_requirements || exit_code=1
    check_ollama || exit_code=1
    check_venv || exit_code=1
    check_agent_files || exit_code=1
    
    if [ $exit_code -eq 0 ]; then
        print_header "Health Check Passed"
        print_success "X-Terraform Agent is ready to use!"
    else
        print_header "Health Check Failed"
        print_error "Please fix the issues above before using X-Terraform Agent"
    fi
    
    return $exit_code
}

# Run main function
main "$@"
