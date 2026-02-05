# Tools & Services

External tools, APIs, and services used in Arbi's infrastructure.

## Blockchain APIs

### Alchemy
**Purpose**: Blockchain data for Base and Solana  
**Tier**: Free (330 requests/second)  
**API Key**: `REDACTED_API_KEY`

**Base Endpoint**:
```
https://base-mainnet.g.alchemy.com/v2/{API_KEY}
```

**Solana Endpoint**:
```
https://solana-mainnet.g.alchemy.com/v2/{API_KEY}
```

**Key Methods**:
- `alchemy_getAssetTransfers` - Transaction history with token metadata
- `alchemy_getTokenBalances` - ERC-20 token holdings
- `getSignaturesForAddress` - Solana transaction signatures
- `getTransaction` - Full Solana transaction details

**Why Alchemy**: More reliable than public RPCs, includes helper methods for tokens, supports both Base and Solana.

### DexScreener
**Purpose**: Real-time token price discovery  
**Tier**: Free (no authentication)  
**Endpoint**: `https://api.dexscreener.com/latest/dex/tokens/{address}`

**Response Structure**:
```json
{
  "pairs": [
    {
      "chainId": "base",
      "priceUsd": "0.000041",
      "liquidity": { "usd": 12345 },
      "priceChange": { "h24": -5.32 }
    }
  ]
}
```

**Usage Pattern**:
1. Query by token address
2. Filter pairs by `chainId` (base, solana, etc.)
3. Select pair with highest liquidity
4. Use `priceUsd` for calculations

**Why DexScreener**: Free, no API key, covers small-cap tokens that CoinGecko doesn't list, real-time DEX data.

### CoinGecko
**Purpose**: ETH and SOL price feeds  
**Tier**: Free (10-30 calls/minute)  
**Endpoint**: `https://api.coingecko.com/api/v3/simple/price`

**Example**:
```bash
curl 'https://api.coingecko.com/api/v3/simple/price?ids=ethereum,solana&vs_currencies=usd'
```

**Response**:
```json
{
  "ethereum": { "usd": 2500.45 },
  "solana": { "usd": 100.23 }
}
```

**Cache Strategy**: 5-minute cache to avoid rate limits.

## Communication

### Discord Webhooks
**Purpose**: Real-time notifications for transactions and emails

**Webhooks**:
- **Email Inbox**: `https://discord.com/api/webhooks/REDACTED_WEBHOOK/...`
- **Onchain Alerts**: `https://discord.com/api/webhooks/REDACTED_WEBHOOK/...`

**Payload Format**:
```json
{
  "content": "<@REDACTED_USER_ID>",
  "embeds": [{
    "title": "New Transaction",
    "color": 5814783,
    "fields": [
      {"name": "From", "value": "0x...", "inline": true},
      {"name": "Value", "value": "1.0 ETH", "inline": true}
    ],
    "timestamp": "2026-02-05T21:00:00Z"
  }]
}
```

**Color Codes**:
- Base: `5814783` (blue)
- Solana: `9055202` (purple)
- Security: `15158332` (red)
- Urgent: `16737843` (coral)

**Why Discord**: Persistent history, mobile notifications, easy integration with OpenClaw.

### Gmail API
**Purpose**: Email monitoring and categorization  
**Authentication**: OAuth 2.0  
**Scope**: `gmail.readonly` (read-only)

**Setup Steps**:
1. Create project in Google Cloud Console
2. Enable Gmail API
3. Create OAuth 2.0 credentials (Desktop app)
4. Download `gmail_credentials.json`
5. Run `gmail_auth.py` to generate token
6. Token saved to `/data/gmail_token.json`

**Key Methods**:
- `users().messages().list()` - List messages with query
- `users().messages().get()` - Get full message details
- `users().messages().modify()` - Mark as read

**Query Examples**:
```python
# Unread emails
service.users().messages().list(userId='me', q='is:unread').execute()

# From specific sender
service.users().messages().list(userId='me', q='from:example.com').execute()
```

**Token Refresh**: Automatic when expired (no manual intervention needed).

## Development Tools

### Docker
**Version**: 24.0.7  
**Compose**: Standalone (not docker-compose command)

**Common Commands**:
```bash
# Build and run
docker build -t image-name .
docker run -d --name container-name -p 3100:3000 image-name

# Logs
docker logs -f container-name

# Restart
docker restart container-name

# Copy files (bypass cache)
docker cp file.js container-name:/app/file.js

# Cleanup
docker system prune -a
```

**Health Checks**:
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:3000/health || exit 1
```

### Nginx
**Version**: Latest stable  
**Config Location**: `/etc/nginx/sites-enabled/`

**Reverse Proxy Pattern**:
```nginx
location /api/wallet/ {
    proxy_pass http://localhost:3100/api/;
    proxy_http_version 1.1;
    proxy_set_header Host $host;
}
```

**SSL Configuration**:
```nginx
ssl_certificate /etc/letsencrypt/live/arbi.betterfuturelabs.xyz-0001/fullchain.pem;
ssl_certificate_key /etc/letsencrypt/live/arbi.betterfuturelabs.xyz-0001/privkey.pem;
```

**Test Config**:
```bash
nginx -t
systemctl reload nginx
```

### Certbot (SSL)
**Installation**: Snap version (`/snap/bin/certbot`)  
**Certificates**: `/etc/letsencrypt/live/arbi.betterfuturelabs.xyz-0001/`

**Renewal**:
```bash
certbot renew --dry-run
```

**Note**: Certificate path has `-0001` suffix due to multiple certificate generations. Always check actual path.

### GitHub CLI
**Purpose**: Manage repositories, secrets, CI/CD  
**Installation**: `gh` command

**Common Commands**:
```bash
# Set secrets for CI/CD
gh secret set SSH_HOST --body "173.255.225.53"
gh secret set SSH_KEY < ~/.ssh/id_ed25519

# View workflow runs
gh run list --limit 5

# View logs
gh run view 123456789 --log

# Rerun failed workflow
gh run rerun 123456789
```

**Repository Management**:
```bash
# Create repo
gh repo create Arbi-BFL/repo-name --public

# View issues
gh issue list

# Create issue
gh issue create --title "Bug" --body "Description"
```

### MkDocs Material
**Purpose**: Documentation site generation  
**Theme**: Material for MkDocs  
**Deployment**: Docker container on port 3200

**Build Locally**:
```bash
pip install mkdocs-material
mkdocs serve
```

**Build for Production**:
```bash
mkdocs build
# Output in site/ directory
```

**Configuration**: `mkdocs.yml` defines nav, theme, plugins.

## CI/CD

### GitHub Actions
**Workflows**: `.github/workflows/deploy.yml` in each repo

**Typical Workflow**:
```yaml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: appleboy/ssh-action@master
        with:
          host: ${{ secrets.SSH_HOST }}
          username: ${{ secrets.SSH_USERNAME }}
          key: ${{ secrets.SSH_KEY }}
          script: |
            cd /root/deployments/project
            git pull origin main
            docker-compose build --no-cache
            docker-compose up -d
            docker image prune -f
```

**Secrets Required**:
- `SSH_HOST`: Server IP
- `SSH_USERNAME`: Usually `root`
- `SSH_KEY`: Private SSH key content

**Trigger**: Every push to `main` branch.

## Monitoring

### Docker Health Checks
Built into each container:
```bash
docker ps  # Shows health status
```

Status indicators:
- `(healthy)` - Service responding
- `(unhealthy)` - Health check failing
- `(starting)` - Still initializing

### Discord Notifications
Real-time alerts for:
- New blockchain transactions
- New emails received
- Service errors

Mentions Arbi (`<@REDACTED_USER_ID>`) for automatic investigation.

### Manual Checks
```bash
# Check all health endpoints
curl https://arbi.betterfuturelabs.xyz/api/wallet/health
curl https://arbi.betterfuturelabs.xyz/api/email/health
curl https://arbi.betterfuturelabs.xyz/api/onchain/health

# Check container status
docker ps

# Check logs
docker logs --tail 50 container-name
```

## Infrastructure

### Linode VPS
**IP**: 173.255.225.53  
**OS**: Ubuntu 22.04 LTS  
**Access**: SSH (root@173.255.225.53)

**Installed Software**:
- Docker + Docker Compose
- Nginx
- Certbot (snap)
- Node.js 20
- Python 3.10
- Git

### DNS
**Domain**: betterfuturelabs.xyz  
**Managed By**: External DNS provider

**Records**:
```
arbi.betterfuturelabs.xyz     A  173.255.225.53
docs.arbi.betterfuturelabs.xyz A  173.255.225.53
data.betterfuturelabs.xyz      A  173.255.225.53
```

### File Structure
```
/root/
├── deployments/
│   ├── arbi-frontend/
│   ├── wallet-dashboard/
│   ├── email-automation/
│   ├── onchain-analytics/
│   └── arbi-docs/
└── .openclaw/
    └── workspace/
        ├── .credentials
        └── projects/
```

## Development Environment

### Local Setup
```bash
# Clone repository
git clone https://github.com/Arbi-BFL/project-name.git
cd project-name

# Install dependencies
npm install  # or pip install -r requirements.txt

# Run locally
npm start  # or python app.py

# Build Docker image
docker build -t project-name .
docker run -d -p 3000:3000 project-name
```

### Environment Variables
Create `.env` file (not committed):
```bash
ALCHEMY_API_KEY=REDACTED_API_KEY
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
GMAIL_TOKEN_PATH=/data/gmail_token.json
```

Load in application:
```python
import os
API_KEY = os.getenv('ALCHEMY_API_KEY')
```

## Useful Commands

### System Administration
```bash
# Disk usage
df -h

# Docker disk usage
docker system df

# Clean up unused images
docker image prune -a

# View running processes
htop

# Check port usage
lsof -i :3100
```

### Debugging
```bash
# Follow logs
docker logs -f container-name

# Inspect container
docker inspect container-name

# Enter container shell
docker exec -it container-name /bin/sh

# Test API
curl -v http://localhost:3100/api/balances

# Check Nginx config
nginx -t
```

### Git Workflow
```bash
# Stage changes
git add -A

# Commit
git commit -m "Description"

# Push (triggers CI/CD)
git push origin main

# View recent commits
git log --oneline -10
```

## External Services (Not Currently Used)

### Why Not PostgreSQL?
SQLite handles our load easily. Would switch if:
- Multiple concurrent writers needed
- Database size exceeds 100GB
- Complex queries needed

### Why Not Redis?
No caching bottleneck yet. Would add if:
- API response time exceeds 500ms
- Multiple instances need shared state

### Why Not WebSockets?
Polling works fine. Would add if:
- Real-time updates critical
- User expects sub-second latency

**Philosophy**: Don't add complexity until it solves a real problem.
