#!/bin/bash
# Network Learning Lab Setup Script
# Learn about automation, networking setup, and system administration

set -e

echo "🌐 Setting up Local Hosting Network Learning Lab"
echo "================================================"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    log_info "Checking prerequisites..."
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install Docker Desktop."
        exit 1
    fi
    
    # Check Docker Compose
    if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
        log_error "Docker Compose is not available."
        exit 1
    fi
    
    # Check if Docker daemon is running
    if ! docker info &> /dev/null; then
        log_error "Docker daemon is not running. Please start Docker Desktop."
        exit 1
    fi
    
    log_success "All prerequisites satisfied"
}

# Setup local DNS entries for learning
setup_local_dns() {
    log_info "Setting up local DNS entries..."
    
    # Backup current hosts file
    if [ ! -f /etc/hosts.backup ]; then
        sudo cp /etc/hosts /etc/hosts.backup
        log_info "Backed up original hosts file to /etc/hosts.backup"
    fi
    
    # DNS entries for our learning lab
    LOCAL_ENTRIES="
# Network Learning Lab - Local DNS entries
127.0.0.1   static.local
127.0.0.1   api.local  
127.0.0.1   python-api.local
127.0.0.1   traefik.local
127.0.0.1   grafana.local
127.0.0.1   prometheus.local
127.0.0.1   netdata.local
"
    
    # Check if entries already exist
    if grep -q "Network Learning Lab" /etc/hosts; then
        log_info "DNS entries already configured"
    else
        echo "$LOCAL_ENTRIES" | sudo tee -a /etc/hosts > /dev/null
        log_success "Added local DNS entries to /etc/hosts"
        log_info "You can now access services using friendly names like static.local"
    fi
}

# Create necessary directories and set permissions
setup_directories() {
    log_info "Setting up project directories..."
    
    # Ensure all directories exist with proper permissions
    mkdir -p logs
    mkdir -p data/{postgres,redis,grafana,prometheus}
    
    # Set appropriate permissions for data directories
    chmod 755 data/*
    
    log_success "Directory structure created"
}

# Build and start services
start_services() {
    log_info "Building and starting services..."
    
    # Stop any existing services
    docker-compose down 2>/dev/null || true
    
    # Build custom images
    log_info "Building Node.js application..."
    docker-compose build node-app
    
    log_info "Building Python API..."
    docker-compose build python-api
    
    # Start core infrastructure first
    log_info "Starting core infrastructure (databases, proxy)..."
    docker-compose up -d postgres redis traefik
    
    # Wait for databases to be ready
    log_info "Waiting for databases to initialize..."
    sleep 10
    
    # Start application services
    log_info "Starting application services..."
    docker-compose up -d static-web node-app python-api
    
    # Start monitoring services
    log_info "Starting monitoring stack..."
    docker-compose up -d prometheus grafana netdata
    
    log_success "All services started successfully!"
}

# Display service information
show_service_info() {
    echo ""
    log_success "🎉 Network Learning Lab is ready!"
    echo ""
    echo "📊 Access your services:"
    echo "   • Main Dashboard:     http://localhost:8080"
    echo "   • Static Website:     http://localhost:8080 or http://static.local"
    echo "   • Node.js API:        http://localhost:8081 or http://api.local"
    echo "   • Python API:         http://localhost:8082 or http://python-api.local"
    echo "   • Traefik Dashboard:  http://localhost:8090 or http://traefik.local"
    echo "   • Grafana:           http://localhost:3000 (admin/admin)"
    echo "   • Prometheus:        http://localhost:9090"
    echo "   • NetData:           http://localhost:19999"
    echo ""
    echo "🗄️  Database Access:"
    echo "   • PostgreSQL:        localhost:5432 (user/password)"
    echo "   • Redis:             localhost:6379"
    echo ""
    echo "🎓 Learning Resources:"
    echo "   • Network monitoring: Check NetData for real-time metrics"
    echo "   • Service discovery: Explore Traefik dashboard"
    echo "   • API testing: Try /network-info endpoints on both APIs"
    echo "   • Database queries: Connect to PostgreSQL and explore tables"
    echo ""
    echo "🔧 Useful Commands:"
    echo "   • View logs:         docker-compose logs -f [service]"
    echo "   • Stop all:          docker-compose down"
    echo "   • Restart service:   docker-compose restart [service]"
    echo "   • Shell access:      docker-compose exec [service] bash"
    echo ""
}

# Health checks
run_health_checks() {
    log_info "Running health checks..."
    
    # Wait a bit for services to fully start
    sleep 5
    
    # Check each service
    services=(
        "static-web:http://localhost:8080"
        "node-app:http://localhost:8081/health"
        "python-api:http://localhost:8082/health"
        "traefik:http://localhost:8090/ping"
        "grafana:http://localhost:3000/api/health"
        "prometheus:http://localhost:9090/-/healthy"
    )
    
    for service_info in "${services[@]}"; do
        service_name=${service_info%%:*}
        service_url=${service_info##*:}
        
        if curl -s -f "$service_url" > /dev/null 2>&1; then
            log_success "$service_name is healthy"
        else
            log_warning "$service_name may not be fully ready yet"
        fi
    done
}

# Clean up function
cleanup() {
    log_info "Cleaning up..."
    docker-compose down
    log_success "Services stopped"
}

# Main execution
main() {
    case "${1:-start}" in
        "start")
            check_prerequisites
            setup_local_dns
            setup_directories
            start_services
            run_health_checks
            show_service_info
            ;;
        "stop")
            cleanup
            ;;
        "restart")
            cleanup
            sleep 2
            main start
            ;;
        "status")
            docker-compose ps
            ;;
        "logs")
            docker-compose logs -f "${2:-}"
            ;;
        *)
            echo "Usage: $0 {start|stop|restart|status|logs [service]}"
            echo ""
            echo "Commands:"
            echo "  start    - Start the entire network learning lab"
            echo "  stop     - Stop all services"
            echo "  restart  - Restart all services"
            echo "  status   - Show service status"
            echo "  logs     - Show logs for all services or specific service"
            exit 1
            ;;
    esac
}

# Handle script interruption
trap cleanup INT

# Run main function with all arguments
main "$@"