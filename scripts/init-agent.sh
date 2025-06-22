#!/bin/bash

# Terraform Agent Initialization Script
# This script sets up the Terraform agent with a specific repository

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
    echo "Usage: $0 [OPTIONS] <repository_path>"
    echo ""
    echo "Options:"
    echo "  -h, --help          Show this help message"
    echo "  -m, --model MODEL   Specify Ollama model to use"
    echo "  -e, --env-file      Path to environment file"
    echo "  -d, --docker        Use Docker mode"
    echo ""
    echo "Examples:"
    echo "  $0 /path/to/terraform/project"
    echo "  $0 -m codellama:7b-instruct /path/to/project"
    echo "  $0 -d -e .env.prod /path/to/project"
}

# Default values
REPO_PATH=""
MODEL="codellama:7b-instruct"
ENV_FILE=""
DOCKER_MODE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -m|--model)
            MODEL="$2"
            shift 2
            ;;
        -e|--env-file)
            ENV_FILE="$2"
            shift 2
            ;;
        -d|--docker)
            DOCKER_MODE=true
            shift
            ;;
        -*)
            print_error "Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$REPO_PATH" ]]; then
                REPO_PATH="$1"
            else
                print_error "Multiple repository paths specified"
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if repository path is provided
if [[ -z "$REPO_PATH" ]]; then
    print_error "Repository path is required"
    show_usage
    exit 1
fi

# Check if repository path exists
if [[ ! -d "$REPO_PATH" ]]; then
    print_error "Repository path does not exist: $REPO_PATH"
    exit 1
fi

# Check if it's a git repository
if [[ ! -d "$REPO_PATH/.git" ]]; then
    print_warning "Path is not a git repository: $REPO_PATH"
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_status "Initializing Terraform Agent..."

# Get absolute path
REPO_PATH=$(realpath "$REPO_PATH")
print_status "Repository path: $REPO_PATH"

# Check for Terraform files
TF_FILES=$(find "$REPO_PATH" -name "*.tf" -o -name "*.tfvars" | wc -l)
if [[ $TF_FILES -eq 0 ]]; then
    print_warning "No Terraform files found in repository"
else
    print_success "Found $TF_FILES Terraform files"
fi

# Create environment file if not provided
if [[ -z "$ENV_FILE" ]]; then
    ENV_FILE=".env"
fi

# Create environment file
print_status "Creating environment file: $ENV_FILE"
cat > "$ENV_FILE" << EOF
# Terraform Agent Configuration
AGENT_MODEL=$MODEL
AGENT_TEMP=0.7
AGENT_MAX_TOKENS=4096

# Terraform Configuration
TF_WORKSPACE=default
TF_BACKEND_TYPE=local

# Git Configuration
GIT_REPO_PATH=$REPO_PATH
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
DATA_DIR=/app/data
LOGS_DIR=/app/logs
DOCS_DIR=/app/docs
EOF

print_success "Environment file created: $ENV_FILE"

# Check if Ollama is installed and running
print_status "Checking Ollama installation..."
if command -v ollama &> /dev/null; then
    print_success "Ollama is installed"
    
    # Check if Ollama is running
    if curl -s http://localhost:11434/api/tags &> /dev/null; then
        print_success "Ollama is running"
        
        # Check if model is available
        if ollama list | grep -q "$MODEL"; then
            print_success "Model $MODEL is available"
        else
            print_warning "Model $MODEL is not available"
            read -p "Pull model $MODEL? (y/N): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                print_status "Pulling model $MODEL..."
                ollama pull "$MODEL"
                print_success "Model pulled successfully"
            fi
        fi
    else
        print_warning "Ollama is not running"
        print_status "Starting Ollama..."
        ollama serve &
        sleep 5
        print_success "Ollama started"
    fi
else
    print_error "Ollama is not installed"
    print_status "Please install Ollama from https://ollama.ai"
    exit 1
fi

# Check if Docker is available (if Docker mode is requested)
if [[ "$DOCKER_MODE" == true ]]; then
    print_status "Checking Docker installation..."
    if command -v docker &> /dev/null && command -v docker-compose &> /dev/null; then
        print_success "Docker and Docker Compose are available"
        
        # Export environment variables for Docker
        export GIT_REPO_PATH="$REPO_PATH"
        export AGENT_MODEL="$MODEL"
        
        print_status "Starting Terraform Agent with Docker..."
        docker-compose up -d
        
        print_success "Terraform Agent started with Docker"
        print_status "Access the agent at: http://localhost:8000"
    else
        print_error "Docker or Docker Compose not available"
        exit 1
    fi
else
    # Check Python dependencies
    print_status "Checking Python dependencies..."
    if command -v python3 &> /dev/null; then
        print_success "Python 3 is available"
        
        # Check if virtual environment exists
        if [[ ! -d "venv" ]]; then
            print_status "Creating virtual environment..."
            python3 -m venv venv
        fi
        
        # Activate virtual environment
        source venv/bin/activate
        
        # Install dependencies
        print_status "Installing Python dependencies..."
        pip install -r requirements.txt
        
        print_success "Dependencies installed"
        
        # Create a simple startup script
        STARTUP_SCRIPT="start-agent.sh"
        cat > "$STARTUP_SCRIPT" << 'EOF'
#!/bin/bash
source venv/bin/activate
export $(cat .env | xargs)
python -m agent.main --interactive
EOF
        
        chmod +x "$STARTUP_SCRIPT"
        print_success "Startup script created: $STARTUP_SCRIPT"
        
        print_status "To start the agent, run: ./$STARTUP_SCRIPT"
    else
        print_error "Python 3 is not available"
        exit 1
    fi
fi

print_success "Terraform Agent initialization complete!"
print_status "Repository: $REPO_PATH"
print_status "Model: $MODEL"
print_status "Environment file: $ENV_FILE"

if [[ "$DOCKER_MODE" == true ]]; then
    echo ""
    echo "Next steps:"
    echo "1. Access the agent at: http://localhost:8000"
    echo "2. Use the CLI: docker exec -it terraform-agent python -m agent.main --interactive"
    echo "3. View logs: docker-compose logs -f terraform-agent"
else
    echo ""
    echo "Next steps:"
    echo "1. Start the agent: ./start-agent.sh"
    echo "2. Or run directly: python -m agent.main --interactive"
    echo "3. View logs in: logs/"
fi

echo ""
print_success "Happy Terraforming! 🚀" 