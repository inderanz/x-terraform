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
