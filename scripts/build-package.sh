#!/bin/bash

# X-Terraform Agent Package Builder
# Version: 0.0.1
# Description: Build distribution packages for macOS and Linux

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
BUILD_DIR="$AGENT_DIR/build"
DIST_DIR="$AGENT_DIR/dist"
VERSION="0.0.1"
PACKAGE_NAME="x-terraform-agent"
FULL_PACKAGE_NAME="${PACKAGE_NAME}-v${VERSION}"

# Logging
LOG_FILE="$AGENT_DIR/logs/build-$(date +%Y%m%d-%H%M%S).log"

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
        echo "linux"
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo "macos"
    else
        echo "unknown"
    fi
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
    print_header "Cleaning Build Directories"
    
    if [ -d "$BUILD_DIR" ]; then
        print_info "Removing build directory: $BUILD_DIR"
        rm -rf "$BUILD_DIR"
    fi
    
    if [ -d "$DIST_DIR" ]; then
        print_info "Removing dist directory: $DIST_DIR"
        rm -rf "$DIST_DIR"
    fi
    
    print_success "Build directories cleaned"
}

# Create build directories
create_build_dirs() {
    print_header "Creating Build Directories"
    
    mkdir -p "$BUILD_DIR"
    mkdir -p "$DIST_DIR"
    mkdir -p "$BUILD_DIR/$FULL_PACKAGE_NAME"
    
    print_success "Build directories created"
}

# Copy agent files
copy_agent_files() {
    print_header "Copying Agent Files"
    
    local target_dir="$BUILD_DIR/$FULL_PACKAGE_NAME"
    
    # Copy main agent files
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
    
    print_success "Agent files copied"
}

# Create platform-specific files
create_platform_files() {
    print_header "Creating Platform-Specific Files"
    
    local target_dir="$BUILD_DIR/$FULL_PACKAGE_NAME"
    local os=$(detect_os)
    local arch=$(get_architecture)
    
    # Create platform info file
    cat > "$target_dir/PLATFORM" << EOF
OS: $os
Architecture: $arch
Build Date: $(date)
Build Host: $(hostname)
EOF
    
    # Create platform-specific installation script
    if [[ "$os" == "macos" ]]; then
        cat > "$target_dir/install-macos.sh" << 'EOF'
#!/bin/bash
# macOS-specific installation script
# This script handles macOS-specific installation requirements

set -e

# Check if Homebrew is installed
if ! command -v brew >/dev/null 2>&1; then
    echo "Homebrew is required for installation on macOS"
    echo "Install Homebrew: https://brew.sh"
    exit 1
fi

# Run main installation script
./install.sh "$@"
EOF
        chmod +x "$target_dir/install-macos.sh"
    elif [[ "$os" == "linux" ]]; then
        cat > "$target_dir/install-linux.sh" << 'EOF'
#!/bin/bash
# Linux-specific installation script
# This script handles Linux-specific installation requirements

set -e

# Detect Linux distribution
if command -v apt-get >/dev/null 2>&1; then
    DISTRO="ubuntu"
elif command -v yum >/dev/null 2>&1; then
    DISTRO="centos"
elif command -v dnf >/dev/null 2>&1; then
    DISTRO="fedora"
else
    DISTRO="unknown"
fi

echo "Detected Linux distribution: $DISTRO"

# Run main installation script
./install.sh "$@"
EOF
        chmod +x "$target_dir/install-linux.sh"
    fi
    
    print_success "Platform-specific files created"
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
    print_header "Creating Package Archive"
    
    local os=$(detect_os)
    local arch=$(get_architecture)
    local package_file="${FULL_PACKAGE_NAME}-${os}-${arch}.tar.gz"
    local package_path="$DIST_DIR/$package_file"
    
    print_info "Creating package: $package_file"
    
    # Create tar.gz archive
    cd "$BUILD_DIR"
    tar -czf "$package_path" "$FULL_PACKAGE_NAME"
    
    # Get package size
    local package_size=$(du -h "$package_path" | cut -f1)
    
    print_success "Package created: $package_path ($package_size)"
    
    # Create checksum for the package
    local package_checksum=$(sha256sum "$package_path" | cut -d' ' -f1)
    echo "$package_checksum  $package_file" > "$DIST_DIR/${package_file}.sha256"
    
    print_success "Package checksum created"
}

# Create release notes
create_release_notes() {
    print_header "Creating Release Notes"
    
    local release_notes_file="$DIST_DIR/release-notes-v${VERSION}.md"
    
    cat > "$release_notes_file" << EOF
# X-Terraform Agent v${VERSION} Release Notes

## Release Date
$(date '+%Y-%m-%d')

## What's New
- Initial release of X-Terraform Agent
- AI-powered Terraform development assistant
- Integration with Ollama and codellama:7b-instruct model
- Comprehensive Terraform module generation and review
- Cross-platform support (macOS & Linux)

## Features
- **Intelligent Code Generation**: Generate Terraform configurations using natural language
- **Code Review & Enhancement**: Review existing Terraform code and suggest improvements
- **Module Development**: Create and enhance Terraform modules
- **Documentation Generation**: Generate comprehensive documentation for Terraform code
- **Troubleshooting**: Identify and fix common Terraform issues
- **Best Practices**: Ensure code follows HashiCorp best practices

## System Requirements
- **Operating System**: macOS 10.15+ or Linux (Ubuntu 18.04+, CentOS 7+, Fedora 30+)
- **RAM**: 8GB minimum (16GB recommended)
- **Storage**: 10GB free space
- **CPU**: 4 cores minimum
- **Network**: Stable internet connection for model download

## Installation
\`\`\`bash
# Download and install
curl -fsSL https://storage.googleapis.com/x-terraform-agent/install.sh | bash

# Or download and run manually
wget https://storage.googleapis.com/x-terraform-agent/${FULL_PACKAGE_NAME}.tar.gz
tar -xzf ${FULL_PACKAGE_NAME}.tar.gz
cd ${FULL_PACKAGE_NAME}
./install.sh
\`\`\`

## Quick Start
\`\`\`bash
# Activate virtual environment
source venv/bin/activate

# Run the agent
./scripts/agent-cli.sh

# Get help
./scripts/agent-cli.sh --help
\`\`\`

## Documentation
- Quick Start Guide: \`docs/QUICKSTART.md\`
- User Manual: \`docs/README.md\`
- Examples: \`examples/\`
- Test Scenarios: \`docs/TEST_SCENARIOS.md\`

## Known Issues
- None at this time

## Support
For issues and questions, please refer to the documentation or create an issue in the project repository.

## Changelog
### v${VERSION} (Initial Release)
- Initial release with core functionality
- Ollama integration with codellama:7b-instruct model
- Terraform code generation and review capabilities
- Cross-platform installation scripts
- Comprehensive documentation and examples
EOF
    
    print_success "Release notes created: $release_notes_file"
}

# Create installation script for GCS
create_gcs_install_script() {
    print_header "Creating GCS Installation Script"
    
    local gcs_install_script="$DIST_DIR/install.sh"
    
    cat > "$gcs_install_script" << 'EOF'
#!/bin/bash

# X-Terraform Agent GCS Installation Script
# This script downloads and installs the X-Terraform Agent from Google Cloud Storage

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
VERSION="0.0.1"
GCS_BASE_URL="https://storage.googleapis.com/x-terraform-agent"
PACKAGE_NAME="x-terraform-agent-v${VERSION}"

# Detect OS and architecture
detect_platform() {
    local os=""
    local arch=""
    
    case "$(uname -s)" in
        Linux*)     os="linux" ;;
        Darwin*)    os="macos" ;;
        *)          os="unknown" ;;
    esac
    
    case "$(uname -m)" in
        x86_64)     arch="x86_64" ;;
        arm64|aarch64) arch="arm64" ;;
        *)          arch="unknown" ;;
    esac
    
    echo "${os}-${arch}"
}

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

# Main installation function
main() {
    print_header "X-Terraform Agent Installation"
    
    local platform=$(detect_platform)
    local package_file="${PACKAGE_NAME}-${platform}.tar.gz"
    local download_url="${GCS_BASE_URL}/releases/v${VERSION}/${package_file}"
    local checksum_url="${GCS_BASE_URL}/releases/v${VERSION}/${package_file}.sha256"
    
    print_info "Detected platform: $platform"
    print_info "Package: $package_file"
    
    # Create temporary directory
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Download package
    print_info "Downloading package..."
    if curl -fsSL -o "$package_file" "$download_url"; then
        print_success "Package downloaded"
    else
        print_error "Failed to download package"
        exit 1
    fi
    
    # Download checksum
    print_info "Downloading checksum..."
    if curl -fsSL -o "${package_file}.sha256" "$checksum_url"; then
        print_success "Checksum downloaded"
    else
        print_warning "Failed to download checksum, skipping verification"
    fi
    
    # Verify checksum if available
    if [ -f "${package_file}.sha256" ]; then
        print_info "Verifying checksum..."
        if sha256sum -c "${package_file}.sha256"; then
            print_success "Checksum verified"
        else
            print_error "Checksum verification failed"
            exit 1
        fi
    fi
    
    # Extract package
    print_info "Extracting package..."
    tar -xzf "$package_file"
    
    # Run installation
    print_info "Running installation..."
    cd "$PACKAGE_NAME"
    ./install.sh "$@"
    
    # Cleanup
    cd /
    rm -rf "$temp_dir"
    
    print_success "Installation completed successfully!"
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
        echo ""
        echo "This script downloads and installs the X-Terraform Agent from Google Cloud Storage."
        exit 0
        ;;
    --verbose|-v)
        set -x
        ;;
esac

# Run main function
main "$@"
EOF
    
    chmod +x "$gcs_install_script"
    print_success "GCS installation script created: $gcs_install_script"
}

# Generate build report
generate_build_report() {
    print_header "Build Report"
    
    local build_report_file="$DIST_DIR/build-report-v${VERSION}.txt"
    local os=$(detect_os)
    local arch=$(get_architecture)
    
    cat > "$build_report_file" << EOF
X-Terraform Agent Build Report
==============================

Version: ${VERSION}
Build Date: $(date)
Build Host: $(hostname)
Operating System: $os
Architecture: $arch

Build Components:
- Agent source code
- Installation scripts
- Documentation
- Examples
- Platform-specific files
- Checksums

Package Files:
- ${FULL_PACKAGE_NAME}-${os}-${arch}.tar.gz
- ${FULL_PACKAGE_NAME}-${os}-${arch}.tar.gz.sha256
- install.sh (GCS installation script)
- release-notes-v${VERSION}.md

Build completed successfully at: $(date)
EOF
    
    print_success "Build report generated: $build_report_file"
}

# Main build function
main() {
    print_header "X-Terraform Agent Package Builder v${VERSION}"
    
    log "Build started at: $(date)"
    log "Agent directory: $AGENT_DIR"
    log "Build directory: $BUILD_DIR"
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
    create_platform_files
    create_checksums
    create_package_archive
    create_release_notes
    create_gcs_install_script
    generate_build_report
    
    # Display completion message
    print_header "Build Completed Successfully"
    
    local os=$(detect_os)
    local arch=$(get_architecture)
    local package_file="${FULL_PACKAGE_NAME}-${os}-${arch}.tar.gz"
    
    log ""
    log "${GREEN}🎉 Package build completed!${NC}"
    log ""
    log "Generated files:"
    log "- ${BLUE}$DIST_DIR/$package_file${NC}"
    log "- ${BLUE}$DIST_DIR/${package_file}.sha256${NC}"
    log "- ${BLUE}$DIST_DIR/install.sh${NC}"
    log "- ${BLUE}$DIST_DIR/release-notes-v${VERSION}.md${NC}"
    log "- ${BLUE}$DIST_DIR/build-report-v${VERSION}.txt${NC}"
    log ""
    log "Next steps:"
    log "1. Test the package locally"
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
        echo "This script builds distribution packages for the X-Terraform Agent."
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
        echo "X-Terraform Agent Package Builder v${VERSION}"
        exit 0
        ;;
esac

# Run main function
main "$@" 