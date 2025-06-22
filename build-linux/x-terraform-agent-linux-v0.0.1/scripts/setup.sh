#!/bin/bash

# Terraform Agent Setup Script
# This script sets up the complete development environment

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
    echo "  -h, --help          Show this help message"
    echo "  -m, --mode MODE     Setup mode (local, docker, both)"
    echo "  -p, --python PATH   Python executable path"
    echo "  -o, --ollama        Install Ollama"
    echo "  -t, --test          Run tests after setup"
    echo "  -c, --clean          Clean previous setup"
    echo ""
    echo "Examples:"
    echo "  $0 --mode local"
    echo "  $0 --mode docker --ollama"
    echo "  $0 --mode both --test"
}

# Default values
SETUP_MODE="local"
PYTHON_PATH=""
INSTALL_OLLAMA=false
RUN_TESTS=false
CLEAN_SETUP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -m|--mode)
            SETUP_MODE="$2"
            shift 2
            ;;
        -p|--python)
            PYTHON_PATH="$2"
            shift 2
            ;;
        -o|--ollama)
            INSTALL_OLLAMA=true
            shift
            ;;
        -t|--test)
            RUN_TESTS=true
            shift
            ;;
        -c|--clean)
            CLEAN_SETUP=true
            shift
            ;;
        -*)
            print_error "Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            print_error "Unexpected argument: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate setup mode
if [[ "$SETUP_MODE" != "local" && "$SETUP_MODE" != "docker" && "$SETUP_MODE" != "both" ]]; then
    print_error "Invalid setup mode: $SETUP_MODE"
    show_usage
    exit 1
fi

print_status "Starting Terraform Agent setup..."
print_status "Setup mode: $SETUP_MODE"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to detect Python
detect_python() {
    if [[ -n "$PYTHON_PATH" ]]; then
        echo "$PYTHON_PATH"
    elif command_exists python3; then
        echo "python3"
    elif command_exists python; then
        echo "python"
    else
        print_error "Python not found. Please install Python 3.8+ or specify with --python"
        exit 1
    fi
}

# Function to check Python version
check_python_version() {
    local python_cmd="$1"
    local version=$($python_cmd --version 2>&1 | cut -d' ' -f2)
    local major=$(echo $version | cut -d'.' -f1)
    local minor=$(echo $version | cut -d'.' -f2)
    
    if [[ $major -lt 3 ]] || [[ $major -eq 3 && $minor -lt 8 ]]; then
        print_error "Python 3.8+ required, found $version"
        exit 1
    fi
    
    print_success "Python version: $version"
}

# Function to clean previous setup
clean_setup() {
    print_status "Cleaning previous setup..."
    
    # Remove virtual environment
    if [[ -d "venv" ]]; then
        rm -rf venv
        print_success "Removed virtual environment"
    fi
    
    # Remove Docker containers and images
    if command_exists docker; then
        docker-compose down --remove-orphans 2>/dev/null || true
        docker rmi terraform-agent 2>/dev/null || true
        print_success "Cleaned Docker containers and images"
    fi
    
    # Remove environment file
    if [[ -f ".env" ]]; then
        rm .env
        print_success "Removed environment file"
    fi
    
    # Remove cache directories
    rm -rf __pycache__ agent/__pycache__ tests/__pycache__ 2>/dev/null || true
    rm -rf .pytest_cache .mypy_cache 2>/dev/null || true
    print_success "Cleaned cache directories"
}

# Function to setup local environment
setup_local() {
    print_status "Setting up local environment..."
    
    local python_cmd=$(detect_python)
    check_python_version "$python_cmd"
    
    # Create virtual environment
    print_status "Creating virtual environment..."
    $python_cmd -m venv venv
    
    # Activate virtual environment
    source venv/bin/activate
    
    # Upgrade pip
    print_status "Upgrading pip..."
    pip install --upgrade pip
    
    # Install dependencies
    print_status "Installing Python dependencies..."
    pip install -r requirements.txt
    
    # Install development dependencies
    print_status "Installing development dependencies..."
    pip install -e .
    
    print_success "Local environment setup complete"
}

# Function to setup Docker environment
setup_docker() {
    print_status "Setting up Docker environment..."
    
    # Check if Docker is installed
    if ! command_exists docker; then
        print_error "Docker not found. Please install Docker first."
        exit 1
    fi
    
    # Check if Docker Compose is installed
    if ! command_exists docker-compose; then
        print_error "Docker Compose not found. Please install Docker Compose first."
        exit 1
    fi
    
    # Build Docker image
    print_status "Building Docker image..."
    docker-compose build
    
    print_success "Docker environment setup complete"
}

# Function to install Ollama
install_ollama() {
    print_status "Installing Ollama..."
    
    if command_exists ollama; then
        print_success "Ollama is already installed"
        return
    fi
    
    # Detect OS and install Ollama
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        print_status "Installing Ollama on macOS..."
        curl -fsSL https://ollama.ai/install.sh | sh
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        print_status "Installing Ollama on Linux..."
        curl -fsSL https://ollama.ai/install.sh | sh
    else
        print_warning "Automatic Ollama installation not supported for this OS"
        print_status "Please install Ollama manually from https://ollama.ai"
        return
    fi
    
    # Start Ollama service
    print_status "Starting Ollama service..."
    ollama serve &
    sleep 5
    
    # Pull default model
    print_status "Pulling default model (codellama:7b-instruct)..."
    ollama pull codellama:7b-instruct
    
    print_success "Ollama installation complete"
}

# Function to run tests
run_tests() {
    print_status "Running tests..."
    
    if [[ "$SETUP_MODE" == "docker" ]]; then
        # Run tests in Docker
        docker-compose run --rm terraform-agent python -m pytest tests/ -v
    else
        # Run tests locally
        source venv/bin/activate
        python -m pytest tests/ -v
    fi
    
    print_success "Tests completed"
}

# Function to create initial environment
create_environment() {
    print_status "Creating initial environment..."
    
    # Create .env file if it doesn't exist
    if [[ ! -f ".env" ]]; then
        cat > .env << EOF
# Terraform Agent Configuration
AGENT_MODEL=codellama:7b-instruct
AGENT_TEMP=0.7
AGENT_MAX_TOKENS=4096

# Terraform Configuration
TF_WORKSPACE=default
TF_BACKEND_TYPE=local

# Git Configuration
GIT_REPO_PATH=./workspace
GIT_BRANCH=main

# Logging Configuration
LOG_LEVEL=INFO
LOG_FORMAT=json

# API Configuration
API_HOST=0.0.0.0
API_PORT=8000

# Ollama Configuration
OLLAMA_HOST=http://localhost:11434
OLLAMA_TIMEOUT=300

# Security Configuration
REQUIRE_APPROVAL=true
AUDIT_LOG_ENABLED=true

# File Paths
DATA_DIR=./data
LOGS_DIR=./logs
DOCS_DIR=./docs
EOF
        print_success "Created .env file"
    fi
    
    # Create necessary directories
    mkdir -p data logs docs
    print_success "Created necessary directories"
}

# Main setup process
main() {
    # Clean setup if requested
    if [[ "$CLEAN_SETUP" == true ]]; then
        clean_setup
    fi
    
    # Install Ollama if requested
    if [[ "$INSTALL_OLLAMA" == true ]]; then
        install_ollama
    fi
    
    # Setup based on mode
    case $SETUP_MODE in
        "local")
            setup_local
            ;;
        "docker")
            setup_docker
            ;;
        "both")
            setup_local
            setup_docker
            ;;
    esac
    
    # Create initial environment
    create_environment
    
    # Run tests if requested
    if [[ "$RUN_TESTS" == true ]]; then
        run_tests
    fi
    
    print_success "Setup complete!"
    print_status ""
    print_status "Next steps:"
    print_status "1. Initialize with your Terraform project: ./scripts/init-agent.sh /path/to/project"
    print_status "2. Start the agent: ./scripts/agent-cli.sh start"
    print_status "3. For Docker mode: ./scripts/agent-cli.sh --docker start"
    print_status ""
    print_status "Documentation: README.md"
    print_status "Configuration: .env"
}

# Run main function
main "$@" 