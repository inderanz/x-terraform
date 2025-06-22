#!/bin/bash

# X-Terraform Agent Linux Package Builder
# Version: 0.0.1
# Description: Build Linux distribution packages for X-Terraform Agent

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LINUX_DIR="$(dirname "$SCRIPT_DIR")"
AGENT_DIR="$(dirname "$LINUX_DIR")"
BUILD_DIR="$AGENT_DIR/build-linux"
DIST_DIR="$AGENT_DIR/dist"
VERSION="0.0.1"
PACKAGE_NAME="x-terraform-agent-linux"
FULL_PACKAGE_NAME="${PACKAGE_NAME}-v${VERSION}"

# Logging
LOG_FILE="$AGENT_DIR/logs/build-linux-$(date +%Y%m%d-%H%M%S).log"

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

# Get system architecture
get_architecture() {
    case "$(uname -m)" in
        x86_64)
            echo "x86_64"
            ;;
        arm64|aarch64)
            echo "arm64"
            ;;
        *)
            echo "unknown"
            ;;
    esac
}

# Clean build directories
clean_build_dirs() {
    print_header "Cleaning Linux Build Directories"
    
    if [ -d "$BUILD_DIR" ]; then
        print_info "Removing Linux build directory: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi
    
    print_success "Linux build directories cleaned"
}

# Create build directories
create_build_dirs() {
    print_header "Creating Linux Build Directories"
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$BUILD_DIR/$FULL_PACKAGE_NAME"
    
    print_success "Linux build directories created"
}

# Copy agent files for Linux
copy_agent_files() {
    print_header "Copying Agent Files for Linux"
    
    local target_dir="$BUILD_DIR/$FULL_PACKAGE_NAME"
    
    # Copy main agent files from the main directory
    cp -r "$AGENT_DIR/agent" "$target_dir/"
    cp -r "$AGENT_DIR/config" "$target_dir/"
    cp -r "$AGENT_DIR/docs" "$target_dir/"
    cp -r "$AGENT_DIR/examples" "$target_dir/"
    cp -r "$AGENT_DIR/scripts" "$target_dir/"
    
    # Copy Ollama model files (for offline installation)
    if [ -d "$AGENT_DIR/ollama-model" ]; then
        cp -r "$AGENT_DIR/ollama-model" "$target_dir/"
        print_success "Ollama model files included (offline installation)"
    else
        print_warning "Ollama model directory not found - will download during installation"
    fi
    
    # Copy root files
    cp "$AGENT_DIR/README.md" "$target_dir/"
    cp "$AGENT_DIR/LICENSE" "$target_dir/"
    cp "$AGENT_DIR/requirements.txt" "$target_dir/"
    cp "$AGENT_DIR/setup.py" "$target_dir/"
    cp "$AGENT_DIR/VERSION.md" "$target_dir/"
    
    # Copy installation scripts
    cp "$AGENT_DIR/install.sh" "$target_dir/"
    cp "$AGENT_DIR/uninstall.sh" "$target_dir/"
    
    # Create VERSION file
    echo "$VERSION" > "$target_dir/VERSION"
    
    print_success "Agent files copied for Linux"
}

# Create Linux-specific files
create_linux_files() {
    print_header "Creating Linux-Specific Files"
    
    local target_dir="$BUILD_DIR/$FULL_PACKAGE_NAME"
    local arch=$(get_architecture)
    
    # Create platform info file
    cat > "$target_dir/PLATFORM" << EOF
OS: linux
Architecture: $arch
Build Date: $(date)
Build Host: $(hostname)
Distribution: Generic Linux
Package Type: Linux-specific
EOF
    
    # Create Linux-specific installation script
    cat > "$target_dir/install-linux.sh" << 'EOF'
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
EOF
    
    chmod +x "$target_dir/install-linux.sh"
    
    # Create Linux-specific start script
    cat > "$target_dir/start-agent-linux.sh" << 'EOF'
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
EOF
    
    chmod +x "$target_dir/start-agent-linux.sh"
    
    # Create Linux-specific health check
    cat > "$target_dir/health-check-linux.sh" << 'EOF'
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
EOF
    
    chmod +x "$target_dir/health-check-linux.sh"
    
    print_success "Linux-specific files created"
}

# Create checksums
create_checksums() {
    print_header "Creating Checksums"
    
    local target_dir="$BUILD_DIR/$FULL_PACKAGE_NAME"
    local checksum_file="$target_dir/checksums.txt"
    
    # Create checksums for all files
    find "$target_dir" -type f -exec sha256sum {} \; > "$checksum_file"
    
    print_success "Checksums created: $checksum_file"
}

# Create package archive
create_package_archive() {
    print_header "Creating Linux Package Archive"
    
    local arch=$(get_architecture)
    local package_file="${FULL_PACKAGE_NAME}-linux-${arch}.tar.gz"
    local package_path="$DIST_DIR/$package_file"
    
    print_info "Creating Linux package: $package_file"
    
    # Create tar.gz archive
    cd "$BUILD_DIR"
    tar -czf "$package_path" "$FULL_PACKAGE_NAME"
    
    # Get package size
    local package_size=$(du -h "$package_path" | cut -f1)
    
    print_success "Linux package created: $package_path ($package_size)"
    
    # Create checksum for the package
    local package_checksum=$(sha256sum "$package_path" | cut -d' ' -f1)
    echo "$package_checksum  $package_file" > "$DIST_DIR/${package_file}.sha256"
    
    print_success "Linux package checksum created"
}

# Create Linux release notes
create_linux_release_notes() {
    print_header "Creating Linux Release Notes"
    
    local release_notes_file="$DIST_DIR/release-notes-linux-v${VERSION}.md"
    local arch=$(get_architecture)
    
    cat > "$release_notes_file" << EOF
# X-Terraform Agent Linux v${VERSION} Release Notes

## Release Date
$(date '+%Y-%m-%d')

## Platform
- **Operating System**: Linux
- **Architecture**: $arch
- **Supported Distributions**: Ubuntu 18.04+, CentOS 7+, Fedora 30+, RHEL 7+

## What's New
- Linux version of X-Terraform Agent
- AI-powered Terraform development assistant
- Integration with Ollama and codellama:7b-instruct model
- Comprehensive Terraform module generation and review
- Linux-specific installation and configuration scripts

## Features
- **Intelligent Code Generation**: Generate Terraform configurations using natural language
- **Code Review & Enhancement**: Review existing Terraform code and suggest improvements
- **Module Development**: Create and enhance Terraform modules
- **Documentation Generation**: Generate comprehensive documentation for Terraform code
- **Troubleshooting**: Identify and fix common Terraform issues
- **Best Practices**: Ensure code follows HashiCorp best practices
- **Linux Optimization**: Optimized for Linux environments

## System Requirements
- **Operating System**: Linux (Ubuntu 18.04+, CentOS 7+, Fedora 30+, RHEL 7+)
- **Architecture**: x86_64 or ARM64
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space
- **CPU**: 4 cores minimum
- **Network**: Stable internet connection for model download

## Installation
\`\`\`bash
# Download the Linux package
gsutil cp gs://x-agents/x-terraform-agent-linux-v${VERSION}-linux-${arch}.tar.gz .

# Extract the package
tar -xzf x-terraform-agent-linux-v${VERSION}-linux-${arch}.tar.gz
cd x-terraform-agent-linux-v${VERSION}

# Run Linux-specific installation
./install-linux.sh
\`\`\`

## Quick Start
\`\`\`bash
# Activate virtual environment
source venv/bin/activate

# Start the agent (Linux-specific)
./start-agent-linux.sh

# Or use CLI commands
./scripts/agent-cli.sh

# Health check
./health-check-linux.sh
\`\`\`

## Linux-Specific Features
- **Automatic System Dependencies**: Installs required packages for your distribution
- **Ollama Integration**: Automatic Ollama installation and service management
- **Service Management**: Uses systemd for Ollama service management
- **Distribution Detection**: Automatically detects and configures for your Linux distribution
- **Health Monitoring**: Linux-specific health check script

## Supported Linux Distributions
- **Ubuntu/Debian**: Automatic package installation via apt
- **CentOS/RHEL/Rocky Linux**: Automatic package installation via yum
- **Fedora**: Automatic package installation via dnf
- **Other**: Manual dependency installation guide provided

## Documentation
- Quick Start Guide: \`docs/QUICKSTART.md\`
- User Manual: \`docs/README.md\`
- Examples: \`examples/\`
- Linux Installation Guide: \`docs/LINUX_INSTALL.md\`

## Known Issues
- None at this time

## Support
For issues and questions, please refer to the documentation or create an issue in the project repository.

## Changelog
### v${VERSION} (Linux Initial Release)
- Initial Linux release with full feature parity
- Linux-specific installation scripts
- Automatic system dependency management
- Ollama service integration
- Distribution-specific optimizations
- Health check and monitoring tools
EOF
    
    print_success "Linux release notes created: $release_notes_file"
}

# Generate Linux build report
generate_linux_build_report() {
    print_header "Linux Build Report"
    
    local build_report_file="$DIST_DIR/build-report-linux-v${VERSION}.txt"
    local arch=$(get_architecture)
    
    cat > "$build_report_file" << EOF
X-Terraform Agent Linux Build Report
====================================

Version: ${VERSION}
Build Date: $(date)
Build Host: $(hostname)
Operating System: Linux
Architecture: $arch

Build Components:
- Agent source code
- Linux-specific installation scripts
- Documentation
- Examples
- Platform-specific files
- Checksums

Package Files:
- ${FULL_PACKAGE_NAME}-linux-${arch}.tar.gz
- ${FULL_PACKAGE_NAME}-linux-${arch}.tar.gz.sha256
- release-notes-linux-v${VERSION}.md

Linux-Specific Features:
- install-linux.sh: Linux-specific installation script
- start-agent-linux.sh: Linux-specific start script
- health-check-linux.sh: Linux-specific health check
- Automatic system dependency installation
- Ollama service management
- Distribution detection and configuration

Build completed successfully at: $(date)
EOF
    
    print_success "Linux build report generated: $build_report_file"
}

# Main build function
main() {
    print_header "X-Terraform Agent Linux Package Builder v${VERSION}"
    
    log "Linux build started at: $(date)"
    log "Linux directory: $LINUX_DIR"
    log "Agent directory: $AGENT_DIR"
    log "Linux build directory: $BUILD_DIR"
    log "Dist directory: $DIST_DIR"
    log ""
    
    # Check prerequisites
    if ! command_exists tar; then
        print_error "tar command not found"
        exit 1
    fi
    
    if ! command_exists sha256sum; then
        print_error "sha256sum command not found"
        exit 1
    fi
    
    # Run build steps
    clean_build_dirs
    create_build_dirs
    copy_agent_files
    create_linux_files
    create_checksums
    create_package_archive
    create_linux_release_notes
    generate_linux_build_report
    
    # Display completion message
    print_header "Linux Build Completed Successfully"
    
    local arch=$(get_architecture)
    local package_file="${FULL_PACKAGE_NAME}-linux-${arch}.tar.gz"
    
    log ""
    log "${GREEN}🎉 Linux package build completed!${NC}"
    log ""
    log "Generated files:"
    log "- ${BLUE}$DIST_DIR/$package_file${NC}"
    log "- ${BLUE}$DIST_DIR/${package_file}.sha256${NC}"
    log "- ${BLUE}$DIST_DIR/release-notes-linux-v${VERSION}.md${NC}"
    log "- ${BLUE}$DIST_DIR/build-report-linux-v${VERSION}.txt${NC}"
    log ""
    log "Linux-specific features:"
    log "- install-linux.sh: Automatic system dependency installation"
    log "- start-agent-linux.sh: Linux-optimized startup"
    log "- health-check-linux.sh: Linux-specific health monitoring"
    log ""
    log "Next steps:"
    log "1. Test the Linux package locally"
    log "2. Upload to GCS bucket"
    log "3. Update download links"
    log ""
    log "Build completed at: $(date)"
    log "Log file: $LOG_FILE"
}

# Handle command line arguments
case "${1:-}" in
    --help|-h)
        echo "Usage: $0 [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --help, -h     Show this help message"
        echo "  --verbose, -v  Enable verbose output"
        echo "  --clean        Clean build directories only"
        echo "  --version      Show version information"
        echo ""
        echo "This script builds Linux distribution packages for the X-Terraform Agent."
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
    --clean)
        clean_build_dirs
        exit 0
        ;;
    --version)
        echo "X-Terraform Agent Linux Package Builder v${VERSION}"
        exit 0
        ;;
esac

# Run main function
main "$@" 