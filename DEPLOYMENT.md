# WinAI Deployment Guide

This guide explains how to deploy the WinAI project to your VM using GitHub Actions with automated Docker Compose deployment.

## Prerequisites

### VM Requirements
- Ubuntu/Debian Linux VM
- Docker and Docker Compose installed
- Ports 80 and 443 open
- SSH access configured
- Domain `winai.hiretechteam.ai` pointing to VM IP `20.193.248.140`

### GitHub Repository Setup
1. Fork or clone this repository to your GitHub account
2. Configure the required secrets in your repository

## GitHub Secrets Configuration

Go to your repository settings → Secrets and variables → Actions, and add these secrets:

| Secret Name | Description | Example |
|-------------|-------------|---------|
| `VM_HOST` | Your VM's IP address or domain | `20.193.248.140` |
| `VM_USER` | SSH username for your VM | `ubuntu` or `root` |
| `VM_SSH_PRIVATE_KEY` | Private SSH key for VM access | Contents of your private key file |
| `LETSENCRYPT_EMAIL` | Email for Let's Encrypt certificates | `your-email@example.com` |

### Setting up SSH Key for GitHub Actions

1. **Generate SSH key pair** (if you don't have one):
   ```bash
   ssh-keygen -t rsa -b 4096 -C "github-actions@winai"
   ```

2. **Add public key to your VM**:
   ```bash
   # Copy public key to VM
   ssh-copy-id -i ~/.ssh/id_rsa.pub user@20.193.248.140
   
   # Or manually add to ~/.ssh/authorized_keys on the VM
   ```

3. **Add private key to GitHub secrets**:
   - Copy the entire contents of your private key file (e.g., `~/.ssh/id_rsa`)
   - Add it as the `VM_SSH_PRIVATE_KEY` secret in GitHub

## Deployment Methods

### Method 1: Automatic Deployment (Recommended)

The GitHub Action will automatically deploy when you push to the `main` branch:

1. **Push your changes**:
   ```bash
   git add .
   git commit -m "Deploy WinAI"
   git push origin main
   ```

2. **Manual trigger** (optional):
   - Go to Actions tab in your GitHub repository
   - Select "Deploy WinAI to VM" workflow
   - Click "Run workflow"

### Method 2: Manual Deployment

If you prefer to deploy manually, you can run the deployment script directly on your VM:

1. **SSH to your VM**:
   ```bash
   ssh user@20.193.248.140
   ```

2. **Run the deployment script**:
   ```bash
   # Set your email for Let's Encrypt
   export LETSENCRYPT_EMAIL="your-email@example.com"
   
   # Download and run the deployment script
   curl -sSL https://raw.githubusercontent.com/jis249/winai/main/deploy.sh | bash
   ```

## Deployment Process

The deployment process performs these steps:

1. **Clone/Update Repository**: Downloads latest code to `/home/azureuser/winai`
2. **Configure SSL Email**: Updates Let's Encrypt email in docker-compose.yml
3. **Start Services**: Runs `docker-compose up -d`
4. **Setup SSL Certificate**: Obtains Let's Encrypt certificate if needed
5. **Verify Deployment**: Checks service status and health endpoints

## Post-Deployment

### Verify Services
```bash
# Check running containers
sudo docker-compose ps

# View logs
sudo docker-compose logs -f

# Test API health
curl https://winai.hiretechteam.ai/health
```

### Test API Endpoints

1. **Health Check**:
   ```bash
   curl https://winai.hiretechteam.ai/health
   ```

2. **Chat Completion**:
   ```bash
   curl -X POST https://winai.hiretechteam.ai/v1/chat/completions \
     -H "Content-Type: application/json" \
     -d '{
       "model": "llama3.2",
       "messages": [{"role": "user", "content": "Hello!"}]
     }'
   ```

3. **List Models**:
   ```bash
   curl https://winai.hiretechteam.ai/v1/models
   ```

## Troubleshooting

### Common Issues

1. **SSL Certificate Issues**:
   ```bash
   # Check certificate status
   sudo docker-compose run --rm certbot certificates
   
   # Renew certificate
   sudo docker-compose run --rm certbot renew
   sudo docker-compose restart nginx
   ```

2. **Service Not Starting**:
   ```bash
   # Check logs
   sudo docker-compose logs ollama
   sudo docker-compose logs nginx
   
   # Restart services
   sudo docker-compose restart
   ```

3. **Models Not Loading**:
   ```bash
   # Check model puller logs
   sudo docker-compose logs pull-models
   
   # Manually pull models
   sudo docker-compose exec ollama ollama pull llama3.2
   ```

### GitHub Actions Debugging

1. **Check workflow logs** in the Actions tab of your repository
2. **Common issues**:
   - SSH connection failures: Check VM_HOST, VM_USER, and SSH key
   - Permission issues: Ensure SSH user has sudo privileges
   - Docker issues: Verify Docker is installed and running on VM

## Security Considerations

- SSH key should be kept secure and rotated regularly
- Consider using a dedicated deployment user with limited privileges
- Monitor deployment logs for any security issues
- Keep Docker and system packages updated

## Maintenance

### Automatic SSL Renewal

Add this to your VM's crontab for automatic certificate renewal:

```bash
# Run every day at noon
0 12 * * * cd /home/azureuser/winai && sudo docker-compose run --rm certbot renew --quiet && sudo docker-compose restart nginx
```

### Updates

To update the application:
1. Push changes to the `main` branch (triggers automatic deployment)
2. Or manually run: `cd /home/azureuser/winai && git pull && sudo docker-compose up -d --build`

## Monitoring

Set up monitoring for:
- Service availability
- SSL certificate expiration
- Resource usage (CPU, memory, disk)
- API response times

Consider using tools like:
- Uptime monitors (Pingdom, StatusCake)
- Log aggregation (ELK stack, Fluentd)
- Metrics collection (Prometheus, Grafana)
