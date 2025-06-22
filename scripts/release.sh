#!/bin/bash

# X-Terraform Agent Release Script
# This script helps create new releases with proper versioning

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -v, --version VERSION    Specify version (e.g., 1.0.1)"
    echo "  -m, --message MESSAGE    Release message"
    echo "  -p, --patch              Increment patch version"
    echo "  -i, --minor              Increment minor version"
    echo "  -j, --major              Increment major version"
    echo "  -d, --dry-run            Show what would be done without executing"
    echo "  -h, --help               Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 -v 1.0.1 -m 'Bug fixes and improvements'"
    echo "  $0 -p -m 'Patch release'"
    echo "  $0 -i -m 'New features added'"
}

# Function to get current version
get_current_version() {
    if [ -f "VERSION.md" ]; then
        grep "^## v" VERSION.md | head -1 | sed 's/## v//'
    else
        echo "0.0.0"
    fi
}

# Function to increment version
increment_version() {
    local version=$1
    local increment_type=$2
    
    IFS='.' read -ra VERSION_PARTS <<< "$version"
    local major=${VERSION_PARTS[0]}
    local minor=${VERSION_PARTS[1]}
    local patch=${VERSION_PARTS[2]}
    
    case $increment_type in
        "major")
            major=$((major + 1))
            minor=0
            patch=0
            ;;
        "minor")
            minor=$((minor + 1))
            patch=0
            ;;
        "patch")
            patch=$((patch + 1))
            ;;
    esac
    
    echo "${major}.${minor}.${patch}"
}

# Function to update version files
update_version_files() {
    local new_version=$1
    
    print_status "Updating version to v${new_version}"
    
    # Update VERSION.md
    if [ -f "VERSION.md" ]; then
        sed -i.bak "s/^## v[0-9]*\.[0-9]*\.[0-9]*/## v${new_version}/" VERSION.md
        rm VERSION.md.bak
    fi
    
    # Update setup.py if it exists
    if [ -f "setup.py" ]; then
        sed -i.bak "s/version=['\"][^'\"]*['\"]/version='${new_version}'/" setup.py
        rm setup.py.bak
    fi
    
    # Update agent version if config exists
    if [ -f "agent/core/config.py" ]; then
        sed -i.bak "s/VERSION = ['\"][^'\"]*['\"]/VERSION = '${new_version}'/" agent/core/config.py
        rm agent/core/config.py.bak
    fi
    
    print_success "Version files updated"
}

# Function to create git tag
create_git_tag() {
    local version=$1
    local message=$2
    
    print_status "Creating git tag v${version}"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "Would run: git tag -a v${version} -m '${message}'"
        echo "Would run: git push origin v${version}"
    else
        git tag -a "v${version}" -m "${message}"
        git push origin "v${version}"
        print_success "Git tag v${version} created and pushed"
    fi
}

# Function to build package
build_package() {
    print_status "Building package"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "Would run: ./scripts/build-package.sh"
    else
        if [ -f "scripts/build-package.sh" ]; then
            chmod +x scripts/build-package.sh
            ./scripts/build-package.sh
            print_success "Package built successfully"
        else
            print_warning "build-package.sh not found, skipping package build"
        fi
    fi
}

# Function to commit changes
commit_changes() {
    local version=$1
    local message=$2
    
    print_status "Committing version changes"
    
    if [ "$DRY_RUN" = "true" ]; then
        echo "Would run: git add ."
        echo "Would run: git commit -m 'Release v${version}: ${message}'"
        echo "Would run: git push origin main"
    else
        git add .
        git commit -m "Release v${version}: ${message}"
        git push origin main
        print_success "Changes committed and pushed"
    fi
}

# Main script logic
main() {
    local version=""
    local message=""
    local increment_type=""
    DRY_RUN="false"
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -v|--version)
                version="$2"
                shift 2
                ;;
            -m|--message)
                message="$2"
                shift 2
                ;;
            -p|--patch)
                increment_type="patch"
                shift
                ;;
            -i|--minor)
                increment_type="minor"
                shift
                ;;
            -j|--major)
                increment_type="major"
                shift
                ;;
            -d|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -h|--help)
                show_usage
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                show_usage
                exit 1
                ;;
        esac
    done
    
    # Validate inputs
    if [ -z "$version" ] && [ -z "$increment_type" ]; then
        print_error "Either version (-v) or increment type (-p/-i/-j) must be specified"
        show_usage
        exit 1
    fi
    
    if [ -z "$message" ]; then
        print_error "Release message (-m) is required"
        show_usage
        exit 1
    fi
    
    # Determine version
    if [ -z "$version" ]; then
        local current_version=$(get_current_version)
        version=$(increment_version "$current_version" "$increment_type")
        print_status "Incrementing version from ${current_version} to ${version}"
    fi
    
    # Validate version format
    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        print_error "Invalid version format: $version. Use format: X.Y.Z"
        exit 1
    fi
    
    print_status "Starting release process for v${version}"
    
    # Check if we're on main branch
    local current_branch=$(git branch --show-current)
    if [ "$current_branch" != "main" ]; then
        print_warning "Not on main branch (current: $current_branch)"
        if [ "$DRY_RUN" != "true" ]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Release cancelled"
                exit 1
            fi
        fi
    fi
    
    # Check for uncommitted changes
    if [ -n "$(git status --porcelain)" ]; then
        print_warning "Uncommitted changes detected"
        if [ "$DRY_RUN" != "true" ]; then
            read -p "Continue anyway? (y/N): " -n 1 -r
            echo
            if [[ ! $REPLY =~ ^[Yy]$ ]]; then
                print_error "Release cancelled"
                exit 1
            fi
        fi
    fi
    
    # Update version files
    update_version_files "$version"
    
    # Build package
    build_package
    
    # Commit changes
    commit_changes "$version" "$message"
    
    # Create git tag
    create_git_tag "$version" "$message"
    
    print_success "Release v${version} process completed!"
    print_status "GitHub Actions will automatically create the release with packages"
    print_status "Check: https://github.com/inderanz/x-terraform/releases"
}

# Run main function
main "$@" 