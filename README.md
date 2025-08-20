# WinAI - OpenAI-Compatible API Server

This project sets up an OpenAI-compatible API server using Ollama with SSL termination via Nginx.

## Domain Setup

- **Domain**: winai.hiretechteam.ai
- **VM IP**: 20.193.248.140
- **SSL**: Automatic certificate management with Let's Encrypt

## Prerequisites

1. Point your domain `winai.hiretechteam.ai` to your VM IP `20.193.248.140`
2. Ensure ports 80 and 443 are open in your firewall
3. Update the email address in `docker-compose.yml` for Let's Encrypt

## Quick Start

1. **Update email**: Edit `docker-compose.yml` and replace `your-email@example.com` with your actual email
2. **Start services**: 
   ```bash
   docker-compose up -d
   ```
3. **Get SSL certificate**: 
   ```bash
   docker-compose run --rm certbot
   ```
4. **Restart nginx**: 
   ```bash
   docker-compose restart nginx
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

## SSL Certificate Renewal

Certificates auto-renew. To set up a cron job for renewal:

```bash
# Add to crontab (crontab -e)
0 12 * * * cd /path/to/winai && docker-compose run --rm certbot renew && docker-compose restart nginx
```

## Security Features

- Rate limiting (10 requests/second with burst of 20)
- HTTPS redirect
- Security headers
- CORS support for browser access

## Monitoring

Check service status:
```bash
docker-compose ps
docker-compose logs -f
```

## Troubleshooting

1. **Certificate issues**: Check domain DNS and firewall settings
2. **502 errors**: Ensure Ollama service is running
3. **Rate limiting**: Adjust nginx configuration if needed
