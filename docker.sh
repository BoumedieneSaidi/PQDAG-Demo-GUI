#!/bin/bash
###############################################################################
# PQDAG Docker Management Script
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

function print_header() {
    echo ""
    echo "=========================================="
    echo -e "${GREEN}$1${NC}"
    echo "=========================================="
    echo ""
}

function print_info() {
    echo -e "${YELLOW}ℹ${NC} $1"
}

function print_success() {
    echo -e "${GREEN}✅${NC} $1"
}

function print_error() {
    echo -e "${RED}❌${NC} $1"
}

# Parse command
COMMAND=${1:-help}

case $COMMAND in
    build)
        print_header "Building Docker Images"
        docker-compose build
        print_success "All images built successfully"
        ;;
        
    up)
        print_header "Starting PQDAG System"
        docker-compose up -d
        print_success "All services started"
        echo ""
        print_info "Frontend: http://localhost:4200"
        print_info "Backend API: http://localhost:8080"
        echo ""
        print_info "Check logs with: ./docker.sh logs"
        ;;
        
    down)
        print_header "Stopping PQDAG System"
        docker-compose down
        print_success "All services stopped"
        ;;
        
    restart)
        print_header "Restarting PQDAG System"
        docker-compose restart
        print_success "All services restarted"
        ;;
        
    logs)
        SERVICE=${2:-}
        if [ -z "$SERVICE" ]; then
            print_header "Showing logs for all services"
            docker-compose logs -f
        else
            print_header "Showing logs for $SERVICE"
            docker-compose logs -f $SERVICE
        fi
        ;;
        
    status)
        print_header "PQDAG Services Status"
        docker-compose ps
        ;;
        
    exec-allocation)
        print_header "Opening shell in allocation container"
        docker-compose exec allocation bash
        ;;
        
    run-allocation)
        print_header "Running allocation pipeline"
        DATASET=${2:-test_dataset}
        print_info "Dataset: $DATASET"
        
        docker-compose exec allocation bash -c "
            python3 generate_config.py $DATASET /app && \
            echo '✅ Config generated' && \
            mpiexec -n 4 python3 stat_MPI.py /app/storage/outputdata /app/storage/allocation_results/db.stat && \
            echo '✅ Statistics computed' && \
            python3 generate_fragments_graph.py /app/storage/allocation_results/db.stat /app/storage/allocation_results/fragments_graph.quad && \
            echo '✅ Fragment graph generated'
        "
        print_success "Allocation pipeline completed"
        ;;
        
    clean)
        print_header "Cleaning Docker resources"
        docker-compose down -v
        docker system prune -f
        print_success "Cleanup completed"
        ;;
        
    rebuild)
        print_header "Rebuilding all services"
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        print_success "Rebuild completed"
        ;;
        
    help|*)
        echo "PQDAG Docker Management Script"
        echo ""
        echo "Usage: ./docker.sh [command] [options]"
        echo ""
        echo "Commands:"
        echo "  build              Build all Docker images"
        echo "  up                 Start all services"
        echo "  down               Stop all services"
        echo "  restart            Restart all services"
        echo "  status             Show services status"
        echo "  logs [service]     Show logs (optionally for specific service)"
        echo "  exec-allocation    Open shell in allocation container"
        echo "  run-allocation     Run allocation pipeline"
        echo "  clean              Clean all Docker resources"
        echo "  rebuild            Rebuild and restart all services"
        echo "  help               Show this help message"
        echo ""
        echo "Examples:"
        echo "  ./docker.sh build"
        echo "  ./docker.sh up"
        echo "  ./docker.sh logs api"
        echo "  ./docker.sh run-allocation watdiv100k"
        echo ""
        ;;
esac
