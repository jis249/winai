#!/bin/bash

# Health Check Script for WinAI
# This script checks the health of all services

DOMAIN="winai.hiretechteam.ai"
APP_DIR="/home/azureuser/winai"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

check_service() {
    local service=$1
    local url=$2
    
    echo -n "Checking $service... "
    
    if curl -sf "$url" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ OK${NC}"
        return 0
    else
        echo -e "${RED}✗ FAILED${NC}"
        return 1
    fi
}

check_docker_services() {
    echo "=== Docker Services ==="
    cd $APP_DIR
    sudo docker-compose ps
    echo ""
}

check_endpoints() {
    echo "=== Endpoint Health Checks ==="
    
    check_service "HTTPS Health" "https://$DOMAIN/health"
    check_service "HTTP Health" "http://$DOMAIN/health"
    check_service "HTTPS API" "https://$DOMAIN/v1/models"
    
    echo ""
}

check_ssl_certificate() {
    echo "=== SSL Certificate ==="
    
    if [ -f "$APP_DIR/ssl/live/$DOMAIN/fullchain.pem" ]; then
        expiry=$(openssl x509 -enddate -noout -in "$APP_DIR/ssl/live/$DOMAIN/fullchain.pem" | cut -d= -f2)
        echo -e "${GREEN}Certificate exists${NC}"
        echo "Expires: $expiry"
        
        # Check if certificate expires in less than 30 days
        expiry_timestamp=$(date -d "$expiry" +%s)
        current_timestamp=$(date +%s)
        days_left=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        if [ $days_left -lt 30 ]; then
            echo -e "${YELLOW}⚠️  Certificate expires in $days_left days${NC}"
        else
            echo -e "${GREEN}Certificate valid for $days_left days${NC}"
        fi
    else
        echo -e "${RED}❌ Certificate not found${NC}"
    fi
    
    echo ""
}

check_disk_space() {
    echo "=== Disk Space ==="
    df -h $APP_DIR
    echo ""
}

check_logs() {
    echo "=== Recent Errors in Logs ==="
    cd $APP_DIR
    sudo docker-compose logs --tail=50 | grep -i error || echo "No recent errors found"
    echo ""
}

main() {
    echo "WinAI Health Check Report"
    echo "========================"
    echo "Date: $(date)"
    echo "Domain: $DOMAIN"
    echo ""
    
    check_docker_services
    check_endpoints
    check_ssl_certificate
    check_disk_space
    check_logs
    
    echo "Health check completed!"
}

main "$@"
