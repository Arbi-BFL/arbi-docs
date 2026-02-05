# Wallet Dashboard

Real-time monitoring dashboard for Arbi's multi-chain cryptocurrency wallets.

## Overview

The Wallet Dashboard provides a beautiful, auto-refreshing interface to monitor wallet balances across Base and Solana networks.

- **Live Demo**: [http://173.255.225.53:3100](http://173.255.225.53:3100)
- **Repository**: [Arbi-BFL/wallet-dashboard](https://github.com/Arbi-BFL/wallet-dashboard)
- **Status**: ✅ Deployed and operational

## Features

### 📊 Multi-Chain Monitoring
- **Base Network** (EVM Layer 2)
- **Solana Network**
- Real-time balance updates every 30 seconds

### 🎨 Modern UI
- Gradient purple theme
- Responsive design
- Mobile-friendly
- Auto-refresh functionality

### 🔌 RESTful API
- `/api/balances` - Get current balances
- `/health` - Health check endpoint

### 🐳 Fully Containerized
- Docker image: `arbi-wallet-dashboard:latest`
- Health checks built-in
- Auto-restart on failure

## Architecture

```
┌─────────────┐
│   Browser   │
└──────┬──────┘
       │ HTTP
       ▼
┌─────────────────┐
│  Nginx (3100)   │
└────────┬────────┘
         │
         ▼
┌──────────────────┐      ┌──────────────┐
│  Node.js/Express │─────▶│  Base RPC    │
│    Container     │      └──────────────┘
└─────────┬────────┘
          │                ┌──────────────┐
          └───────────────▶│  Solana RPC  │
                           └──────────────┘
```

## Wallets Monitored

| Network | Address |
|---------|---------|
| **Base** | `0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6` |
| **Solana** | `FeB1jqjCFKyQ2vVTPLgYmZu1yLvBWhsGoudP46fhhF8z` |

## API Reference

### Get Balances

```bash
curl http://173.255.225.53:3100/api/balances
```

**Response:**
```json
{
  "base": {
    "address": "0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6",
    "balance": "0.004471614096735506",
    "network": "Base Mainnet"
  },
  "solana": {
    "address": "FeB1jqjCFKyQ2vVTPLgYmZu1yLvBWhsGoudP46fhhF8z",
    "balance": "0.000000000",
    "network": "Solana Mainnet"
  },
  "timestamp": "2026-02-05T05:02:07.612Z"
}
```

### Health Check

```bash
curl http://173.255.225.53:3100/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-02-05T05:02:07.612Z"
}
```

## Technology Stack

- **Backend**: Node.js + Express
- **Blockchain**: ethers.js (Base), @solana/web3.js (Solana)
- **RPC**: Public Base RPC, Solana mainnet-beta
- **Frontend**: Vanilla HTML/CSS/JavaScript
- **Container**: Docker (Node 20 Alpine)
- **Deployment**: GitHub Actions CI/CD

## Local Development

```bash
# Clone repository
git clone https://github.com/Arbi-BFL/wallet-dashboard.git
cd wallet-dashboard

# Install dependencies
npm install

# Start dev server
npm run dev

# Visit http://localhost:3000
```

## Docker Deployment

```bash
# Build image
docker build -t arbi-wallet-dashboard .

# Run container
docker run -d \
  --name wallet-dashboard \
  -p 3100:3000 \
  arbi-wallet-dashboard

# Check logs
docker logs -f wallet-dashboard
```

## CI/CD Pipeline

Every push to `main` triggers:

1. ✅ Build Docker image
2. ✅ Run health check tests
3. ✅ Deploy to production server
4. ✅ Verify deployment health

See [CI/CD documentation](../infrastructure/ci-cd.md) for details.

## Monitoring

**Container Health:**
```bash
docker ps | grep wallet-dashboard
```

**Application Logs:**
```bash
docker logs -f arbi-wallet-dashboard
```

**Health Status:**
```bash
curl http://localhost:3100/health
```

## Future Enhancements

- [ ] Transaction history
- [ ] Price feeds (USD value)
- [ ] Gas price tracking
- [ ] Multi-wallet support
- [ ] Alerts and notifications
- [ ] Historical charts

## Troubleshooting

**Container unhealthy?**
```bash
docker logs arbi-wallet-dashboard
docker restart arbi-wallet-dashboard
```

**RPC errors?**
```bash
# Check RPC connectivity
curl https://mainnet.base.org
curl https://api.mainnet-beta.solana.com
```

**Port conflict?**
```bash
# Check what's using port 3100
lsof -i :3100
```
