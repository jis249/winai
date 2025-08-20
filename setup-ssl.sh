#!/bin/bash

# SSL Certificate Setup Script
# Run this script to obtain SSL certificates for your domain

echo "Setting up SSL certificates for winai.hiretechteam.ai..."

# Create SSL directory
mkdir -p ssl

# Update your email in docker-compose.yml before running this
echo "Please update the email address in docker-compose.yml certbot service before proceeding."
echo "Then run: docker-compose up -d nginx"
echo "Wait for nginx to start, then run: docker-compose run --rm certbot"

# After getting certificates, restart nginx
echo "After certificates are obtained, restart nginx with:"
echo "docker-compose restart nginx"

# Auto-renewal setup (add to crontab)
echo "To set up auto-renewal, add this to your crontab:"
echo "0 12 * * * cd /path/to/your/project && docker-compose run --rm certbot renew && docker-compose restart nginx"
