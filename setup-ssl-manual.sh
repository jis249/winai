#!/bin/bash

# SSL Setup Script for WinAI
# This script sets up SSL certificates and switches nginx to HTTPS

set -e

DOMAIN="winai.hiretechteam.ai"
APP_DIR="/opt/winai"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

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

setup_ssl() {
    log "Setting up SSL certificates for $DOMAIN..."
    
    cd $APP_DIR
    
    # Check if certificate already exists
    if [ -f "ssl/live/$DOMAIN/fullchain.pem" ]; then
        log "SSL certificate already exists"
        return 0
    fi
    
    # Make sure nginx is running with HTTP-only config first
    log "Starting with HTTP-only configuration..."
    
    # Copy the HTTP-only nginx config
    $SUDO cp nginx-initial.conf nginx-current.conf
    
    # Update docker-compose to use the initial config
    $SUDO sed -i 's|./nginx.conf:/etc/nginx/nginx.conf:ro|./nginx-current.conf:/etc/nginx/nginx.conf:ro|g' docker-compose.yml
    
    # Restart nginx with HTTP-only config
    $SUDO docker-compose up -d nginx
    
    # Wait for nginx to be ready
    log "Waiting for nginx to be ready..."
    sleep 10
    
    # Test if nginx is responding
    for i in {1..30}; do
        if curl -sf http://localhost/.well-known/acme-challenge/ >/dev/null 2>&1 || curl -sf http://localhost/health >/dev/null 2>&1; then
            log "Nginx is ready for certificate generation"
            break
        fi
        if [ $i -eq 30 ]; then
            warn "Nginx may not be fully ready, continuing anyway..."
        fi
        sleep 2
    done
    
    # Generate SSL certificate
    log "Requesting SSL certificate from Let's Encrypt..."
    if ! $SUDO docker-compose run --rm certbot; then
        error "Failed to obtain SSL certificate"
    fi
    
    # Switch to HTTPS configuration
    log "Switching to HTTPS configuration..."
    $SUDO cp nginx.conf nginx-current.conf
    $SUDO docker-compose restart nginx
    
    # Verify HTTPS is working
    log "Verifying HTTPS setup..."
    sleep 10
    
    if curl -sf https://$DOMAIN/health >/dev/null 2>&1; then
        log "✅ HTTPS is working correctly!"
    else
        warn "⚠️  HTTPS may need more time to propagate"
    fi
    
    log "SSL setup completed successfully!"
}

main() {
    log "Starting SSL setup for WinAI..."
    setup_ssl
    log "SSL setup process finished!"
}

main "$@"
