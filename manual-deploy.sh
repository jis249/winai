#!/bin/bash

# Manual WinAI Deployment Script
# This script deploys the WinAI application by transferring files directly

set -e

# Configuration
APP_DIR="/home/azureuser/winai"
DOMAIN="winai.hiretechteam.ai"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

# Function to check if Docker is installed
check_docker() {
    if ! command -v docker &> /dev/null; then
        error "Docker is not installed. Please install Docker first."
    fi
    
    if ! command -v docker-compose &> /dev/null; then
        error "Docker Compose is not installed. Please install Docker Compose first."
    fi
    
    log "Docker and Docker Compose are installed"
}

# Function to setup the application (assumes files are already present)
setup_app() {
    log "Setting up application directory..."
    
    # Create app directory if it doesn't exist
    mkdir -p $APP_DIR
    cd $APP_DIR
    
    # Check if required files exist
    if [ ! -f "docker-compose.yml" ]; then
        error "docker-compose.yml not found. Please ensure all project files are in $APP_DIR"
    fi
    
    if [ ! -f "nginx.conf" ]; then
        error "nginx.conf not found. Please ensure all project files are in $APP_DIR"
    fi
    
    # Create SSL directory
    mkdir -p ssl
    
    log "Application setup completed"
}

# Function to configure email for Let's Encrypt
configure_email() {
    if [ -z "$LETSENCRYPT_EMAIL" ]; then
        read -p "Enter your email for Let's Encrypt certificates: " LETSENCRYPT_EMAIL
        if [ -z "$LETSENCRYPT_EMAIL" ]; then
            error "Email is required for Let's Encrypt certificates"
        fi
    fi
    
    log "Configuring Let's Encrypt email: $LETSENCRYPT_EMAIL"
    sed -i "s/your-email@example.com/$LETSENCRYPT_EMAIL/g" docker-compose.yml
}

# Function to deploy the application
deploy_app() {
    log "Deploying application..."
    
    # Stop existing containers
    docker-compose down || true
    
    # Start services
    log "Starting services..."
    docker-compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Check if Ollama is ready
    for i in {1..30}; do
        if curl -sf http://localhost/health > /dev/null 2>&1; then
            log "Services are ready!"
            break
        fi
        if [ $i -eq 30 ]; then
            warn "Services may not be fully ready yet, continuing..."
        fi
        sleep 2
    done
}

# Function to setup SSL certificate
setup_ssl() {
    if [ ! -f "ssl/live/$DOMAIN/fullchain.pem" ]; then
        log "Setting up SSL certificate..."
        docker-compose run --rm certbot
        docker-compose restart nginx
        log "SSL certificate setup completed"
    else
        log "SSL certificate already exists"
    fi
}

# Function to show deployment status
show_status() {
    log "Deployment Status:"
    echo "==================="
    docker-compose ps
    
    echo ""
    log "Testing health endpoint..."
    if curl -sf https://$DOMAIN/health > /dev/null 2>&1; then
        log "✅ HTTPS health check: PASSED"
    elif curl -sf http://$DOMAIN/health > /dev/null 2>&1; then
        warn "⚠️  HTTP health check: PASSED (HTTPS may need time to propagate)"
    else
        warn "❌ Health check: FAILED (services may still be starting)"
    fi
    
    echo ""
    log "Recent logs:"
    docker-compose logs --tail=10
    
    echo ""
    log "Deployment completed!"
    log "API Base URL: https://$DOMAIN"
    log "Health Check: https://$DOMAIN/health"
}

# Main deployment process
main() {
    log "Starting WinAI manual deployment..."
    log "Note: This script assumes all project files are already in $APP_DIR"
    
    check_docker
    setup_app
    configure_email
    deploy_app
    setup_ssl
    show_status
    
    log "🎉 WinAI has been successfully deployed!"
    echo ""
    echo "Next steps:"
    echo "1. Test the API: curl https://$DOMAIN/health"
    echo "2. Use the OpenAI-compatible endpoint: https://$DOMAIN/v1"
    echo "3. Monitor logs: cd $APP_DIR && docker-compose logs -f"
}

# Run main function
main "$@"
