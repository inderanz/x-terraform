#!/bin/bash

# Terraform Agent CLI Wrapper
# This script provides easy access to the Terraform agent

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
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  start               Start the agent in interactive mode"
    echo "  query <text>        Send a single query to the agent"
    echo "  analyze             Analyze Terraform files in the repository"
    echo "  validate <file>     Validate a specific Terraform file"
    echo "  status              Show repository and agent status"
    echo "  logs                Show agent logs"
    echo "  stop                Stop the agent (Docker mode only)"
    echo "  restart             Restart the agent (Docker mode only)"
    echo "  help                Show this help message"
    echo ""
    echo "Options:"
    echo "  --docker            Use Docker mode"
    echo "  --model MODEL       Specify Ollama model to use"
    echo "  --no-approval       Skip approval prompts"
    echo "  --verbose           Enable verbose logging"
    echo ""
    echo "Examples:"
    echo "  $0 start"
    echo "  $0 query 'Create a VPC with public and private subnets'"
    echo "  $0 analyze"
    echo "  $0 --docker start"
    echo "  $0 --model codellama:7b-instruct query 'Review my main.tf'"
}

# Default values
COMMAND=""
DOCKER_MODE=false
MODEL=""
NO_APPROVAL=false
VERBOSE=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        start|query|analyze|validate|status|logs|stop|restart|help)
            if [[ -z "$COMMAND" ]]; then
                COMMAND="$1"
            else
                print_error "Multiple commands specified"
                show_usage
                exit 1
            fi
            shift
            ;;
        --docker)
            DOCKER_MODE=true
            shift
            ;;
        --model)
            MODEL="$2"
            shift 2
            ;;
        --no-approval)
            NO_APPROVAL=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option $1"
            show_usage
            exit 1
            ;;
        *)
            # If no command specified, treat as query
            if [[ -z "$COMMAND" ]]; then
                COMMAND="query"
                QUERY_TEXT="$1"
            else
                print_error "Unexpected argument: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# If no command specified, default to start
if [[ -z "$COMMAND" ]]; then
    COMMAND="start"
fi

# Check if .env file exists
if [[ ! -f ".env" ]]; then
    print_error "Environment file .env not found"
    print_status "Please run ./scripts/init-agent.sh first"
    exit 1
fi

# Load environment variables
export $(cat .env | xargs)

# Function to run agent command
run_agent() {
    local args="$1"
    
    if [[ "$DOCKER_MODE" == true ]]; then
        # Docker mode
        if [[ "$COMMAND" == "start" ]]; then
            docker-compose up -d
            print_success "Agent started with Docker"
            print_status "Access at: http://localhost:8000"
            print_status "For interactive mode: docker exec -it terraform-agent python -m agent.main --interactive"
        elif [[ "$COMMAND" == "stop" ]]; then
            docker-compose down
            print_success "Agent stopped"
        elif [[ "$COMMAND" == "restart" ]]; then
            docker-compose restart
            print_success "Agent restarted"
        elif [[ "$COMMAND" == "logs" ]]; then
            docker-compose logs -f terraform-agent
        else
            # Execute command in running container
            docker exec -it terraform-agent python -m agent.main $args
        fi
    else
        # Local mode
        if [[ ! -d "venv" ]]; then
            print_error "Virtual environment not found"
            print_status "Please run ./scripts/init-agent.sh first"
            exit 1
        fi
        
        # Activate virtual environment
        source venv/bin/activate
        
        # Run the agent
        python -m agent.main $args
    fi
}

# Handle different commands
case $COMMAND in
    start)
        print_status "Starting Terraform Agent..."
        if [[ "$DOCKER_MODE" == true ]]; then
            run_agent ""
        else
            run_agent "--interactive"
        fi
        ;;
    query)
        if [[ -z "$QUERY_TEXT" ]]; then
            print_error "Query text is required"
            show_usage
            exit 1
        fi
        
        print_status "Processing query: $QUERY_TEXT"
        
        # Build arguments
        ARGS="\"$QUERY_TEXT\""
        if [[ "$NO_APPROVAL" == true ]]; then
            ARGS="$ARGS --no-approval"
        fi
        if [[ "$VERBOSE" == true ]]; then
            ARGS="$ARGS --verbose"
        fi
        if [[ -n "$MODEL" ]]; then
            ARGS="$ARGS --model $MODEL"
        fi
        
        run_agent $ARGS
        ;;
    analyze)
        print_status "Analyzing Terraform files..."
        run_agent "--analyze"
        ;;
    validate)
        if [[ -z "$2" ]]; then
            print_error "File path is required for validate command"
            show_usage
            exit 1
        fi
        
        print_status "Validating file: $2"
        run_agent "--validate $2"
        ;;
    status)
        print_status "Getting status..."
        run_agent "--status"
        ;;
    logs)
        if [[ "$DOCKER_MODE" == true ]]; then
            run_agent ""
        else
            print_status "Logs are available in logs/ directory"
            if [[ -d "logs" ]]; then
                ls -la logs/
            else
                print_warning "Logs directory not found"
            fi
        fi
        ;;
    stop)
        if [[ "$DOCKER_MODE" == true ]]; then
            run_agent ""
        else
            print_warning "Stop command only available in Docker mode"
            print_status "Use Ctrl+C to stop the agent in local mode"
        fi
        ;;
    restart)
        if [[ "$DOCKER_MODE" == true ]]; then
            run_agent ""
        else
            print_warning "Restart command only available in Docker mode"
            print_status "Stop the agent with Ctrl+C and start again"
        fi
        ;;
    help)
        show_usage
        ;;
    *)
        print_error "Unknown command: $COMMAND"
        show_usage
        exit 1
        ;;
esac 