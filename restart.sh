#!/bin/bash

# Restart Script for WinAI
# This script safely restarts all services

APP_DIR="/opt/winai"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Check if running as root or with sudo
if [[ $EUID -eq 0 ]]; then
    SUDO=""
else
    SUDO="sudo"
fi

restart_services() {
    log "Restarting WinAI services..."
    
    cd $APP_DIR
    
    # Stop services gracefully
    log "Stopping services..."
    $SUDO docker-compose down
    
    # Wait a moment
    sleep 5
    
    # Start services
    log "Starting services..."
    $SUDO docker-compose up -d
    
    # Wait for services to be ready
    log "Waiting for services to start..."
    sleep 30
    
    # Show status
    log "Service status:"
    $SUDO docker-compose ps
    
    # Test health
    log "Testing health endpoint..."
    if curl -sf http://localhost/health >/dev/null 2>&1; then
        log "✅ Services are healthy!"
    else
        warn "⚠️  Services may still be starting..."
    fi
}

main() {
    log "WinAI Service Restart"
    echo "===================="
    
    if [ ! -d "$APP_DIR" ]; then
        echo "Error: Application directory $APP_DIR not found!"
        exit 1
    fi
    
    restart_services
    
    log "Restart completed!"
}

main "$@"
