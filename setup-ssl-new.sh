#!/bin/bash

# SSL Certificate Setup Script for WinAI
# This script helps set up SSL certificates with a new email to avoid rate limits

set -e

EMAIL="jis.thottan@waiin.com"
DOMAIN="winai.hiretechteam.ai"

echo "=== WinAI SSL Certificate Setup ==="
echo "Email: $EMAIL"
echo "Domain: $DOMAIN"

cd /opt/winai

# Check if containers are running
echo "=== Checking container status ==="
sudo docker-compose ps

# Check current certificates
echo "=== Checking existing certificates ==="
if [ -f "ssl/live/$DOMAIN/fullchain.pem" ]; then
    echo "✅ Certificate found:"
    sudo ls -la ssl/live/$DOMAIN/
    echo "Certificate expires:"
    sudo openssl x509 -in ssl/live/$DOMAIN/fullchain.pem -text -noout | grep "Not After"
else
    echo "❌ No existing certificates found"
fi

# Update email in docker-compose.yml
echo "=== Updating email in docker-compose.yml ==="
sudo sed -i "s|--email [^[:space:]]*|--email $EMAIL|g" docker-compose.yml

# Verify email update
echo "=== Verifying email update ==="
if grep -q "$EMAIL" docker-compose.yml; then
    echo "✅ Email updated successfully"
    grep "email" docker-compose.yml
else
    echo "❌ Email update failed"
    exit 1
fi

# Try to get new certificate
echo "=== Attempting to get SSL certificate ==="
echo "Note: If you get a rate limit error, wait until tomorrow and try again"

if sudo docker-compose run --rm certbot; then
    echo "✅ SSL certificate obtained successfully!"
    
    # Switch to HTTPS configuration
    echo "=== Switching to HTTPS configuration ==="
    sudo cp nginx.conf nginx-current.conf
    sudo docker-compose restart nginx
    
    # Test HTTPS endpoint
    echo "=== Testing HTTPS endpoints ==="
    sleep 10
    
    if curl -f https://$DOMAIN/health; then
        echo "✅ HTTPS health endpoint working!"
    else
        echo "❌ HTTPS health endpoint failed"
    fi
    
    if curl -f https://$DOMAIN/v1/models; then
        echo "✅ HTTPS models endpoint working!"
    else
        echo "❌ HTTPS models endpoint failed"
    fi
    
else
    echo "❌ SSL certificate generation failed"
    echo "Common reasons:"
    echo "1. Rate limit reached (wait 24 hours)"
    echo "2. DNS not pointing to this server"
    echo "3. Port 80 not accessible from internet"
    echo ""
    echo "Continuing with HTTP configuration..."
fi

echo "=== Final status ==="
sudo docker-compose ps
echo "=== Recent nginx logs ==="
sudo docker-compose logs nginx --tail=5

echo "=== Setup complete! ==="
