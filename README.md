# WinAI - OpenAI-Compatible API Server

This project sets up an OpenAI-compatible API server using Ollama with SSL termination via Nginx.

## Domain Setup

- **Domain**: winai.hiretechteam.ai
- **VM IP**: 20.193.248.140
- **SSL**: Automatic certificate management with Let's Encrypt

## Project Structure

```
winai/
├── .github/workflows/deploy.yml  # Automated GitHub Actions deployment
├── docker-compose.yml            # Container orchestration
├── nginx.conf                    # HTTPS nginx configuration
├── nginx-http-only.conf          # HTTP-only nginx configuration
├── README.md                     # This file
└── DEPLOYMENT.md                 # Detailed deployment instructions
```

## Automated Deployment (Recommended)

This project is designed for **fully automated deployment** using GitHub Actions:

### Setup Steps

1. **Fork this repository** to your GitHub account
2. **Configure GitHub Secrets**:
   - `VM_HOST`: Your VM IP (20.193.248.140)
   - `VM_USER`: SSH username (usually `azureuser`)
   - `VM_SSH_PRIVATE_KEY`: Your SSH private key content
   - `LETSENCRYPT_EMAIL`: Your email for SSL certificates
   - `PAT_TOKEN`: GitHub Personal Access Token (optional, for private repos)

3. **Deploy**: Push any change to the `main` branch to trigger deployment

### What the Automation Does

✅ **Clones** latest code to `/opt/winai` on your VM  
✅ **Configures** nginx with correct port mappings  
✅ **Starts** all services (Ollama, Nginx, Certbot)  
✅ **Downloads** AI models (llama3.2, mxbai-embed-large)  
✅ **Obtains** SSL certificates (when rate limits allow)  
✅ **Tests** all endpoints automatically  
✅ **Handles** fallback to HTTP if SSL fails  

## Manual Deployment (Alternative)

If you prefer manual deployment:

1. **Clone to VM**: 
   ```bash
   sudo rm -rf /opt/winai
   sudo mkdir -p /opt/winai
   cd /opt/winai
   sudo git clone https://github.com/YOUR_USERNAME/winai.git .
   ```

2. **Update email**: Edit `docker-compose.yml` and replace email with your actual email

3. **Start services**: 
   ```bash
   sudo docker-compose up -d
   ```

4. **SSL certificates**: Will be obtained automatically, or manually run:
   ```bash
   sudo docker-compose run --rm certbot
   sudo docker-compose restart nginx
   ```

## API Usage

Once running, you can use your domain as an OpenAI-compatible endpoint:

### Base URL
```
https://winai.hiretechteam.ai
```

### Example Usage with OpenAI SDK

```python
from openai import OpenAI

client = OpenAI(
    base_url="https://winai.hiretechteam.ai/v1",
    api_key="dummy-key"  # Ollama doesn't require a real API key
)

response = client.chat.completions.create(
    model="llama3.2",
    messages=[
        {"role": "user", "content": "Hello, how are you?"}
    ]
)

print(response.choices[0].message.content)
```

### cURL Example
```bash
curl -X POST https://winai.hiretechteam.ai/v1/chat/completions \
  -H "Content-Type: application/json" \
  -d '{
    "model": "llama3.2",
    "messages": [{"role": "user", "content": "Hello!"}]
  }'
```

## Available Models

The setup automatically pulls:
- `llama3.2` - Chat completion model
- `mxbai-embed-large` - Embedding model

## Endpoints

- `/v1/chat/completions` - OpenAI-compatible chat completions
- `/v1/embeddings` - OpenAI-compatible embeddings
- `/api/*` - Direct Ollama API access
- `/health` - Health check endpoint

## Monitoring & Management

**Check service status:**
```bash
sudo docker-compose ps
sudo docker-compose logs -f nginx
sudo docker-compose logs -f ollama
```

**Restart services:**
```bash
sudo docker-compose restart
```

**Health check:**
```bash
curl http://localhost/health
curl https://winai.hiretechteam.ai/health
```

## Security Features

- **Rate limiting**: 10 requests/second with burst of 20
- **HTTPS redirect**: Automatic HTTP to HTTPS redirect
- **Security headers**: HSTS, X-Frame-Options, etc.
- **CORS support**: Cross-origin requests enabled for browser access

## SSL Certificate Auto-Renewal

Certificates auto-renew. For manual renewal:

```bash
sudo docker-compose run --rm certbot renew
sudo docker-compose restart nginx
```

## Troubleshooting

1. **Certificate issues**: Check domain DNS and firewall settings
2. **502 errors**: Ensure Ollama service is running with correct port (11434)
3. **Rate limiting**: Let's Encrypt limits 5 certs per week per domain
4. **Deployment issues**: Check GitHub Actions logs and [DEPLOYMENT.md](DEPLOYMENT.md)
