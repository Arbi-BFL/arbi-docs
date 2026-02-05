# Wallet Dashboard

Real-time monitoring dashboard for Arbi's multi-chain cryptocurrency wallets with comprehensive token tracking and USD value calculation.

## Overview

The Wallet Dashboard provides a beautiful, auto-refreshing interface to monitor wallet balances, token holdings, and portfolio value across Base and Solana networks.

- **Frontend**: [https://arbi.betterfuturelabs.xyz/wallet](https://arbi.betterfuturelabs.xyz/wallet)
- **API**: https://arbi.betterfuturelabs.xyz/api/wallet/* (proxied from port 3100)
- **Repository**: [Arbi-BFL/wallet-dashboard](https://github.com/Arbi-BFL/wallet-dashboard)
- **Status**: ✅ Deployed and operational

## Features

### 💰 Total Portfolio Balance
- **Unified calculation**: Native + tokens across all chains
- Real-time USD value aggregation
- Breakdown by native vs. token holdings
- Displayed on main dashboard and wallet page

### 📊 Multi-Chain Monitoring
- **Base Network** (EVM Layer 2): ETH and ERC-20 tokens
- **Solana Network**: SOL and SPL tokens
- Real-time balance updates
- USD value conversion for all assets

### 🪙 Token Holdings
- **ERC-20 Detection** (Base): All tokens via Alchemy API
- **Price Integration**: DexScreener for real-time token prices
- **Filtering**: Excludes tokens with no liquidity/price
- **Search**: Find tokens by symbol, name, or address
- **Details per token**:
  - Balance
  - Current price (USD)
  - 24h price change (%)
  - Total value (USD)
  - Network badge

### 🎨 Neobrutalist UI
- Bold color scheme with high contrast
- Thick 4px borders and flat shadows
- Black text on all cards for readability
- Mobile-responsive design
- Integrated into unified frontend

### 🔌 RESTful API
- `GET /api/balances` - Native balances with USD values
- `GET /api/tokens` - All token holdings with prices
- `GET /health` - Health check endpoint

### 🐳 Fully Containerized
- Docker image with health checks
- Auto-restart on failure
- Persistent data volumes

## Architecture

```
┌──────────────────────┐
│  Unified Frontend    │
│  (port 3500)         │
└──────────┬───────────┘
           │ /api/wallet/*
           ▼
┌──────────────────────┐
│  Nginx Reverse Proxy │
└──────────┬───────────┘
           │ proxy to :3100
           ▼
┌──────────────────────┐      ┌──────────────────┐
│  Node.js/Express     │─────▶│  Alchemy API     │
│  Wallet Backend      │      │  (Base & Solana) │
│  (port 3100)         │      └──────────────────┘
└──────────┬───────────┘
           │                   ┌──────────────────┐
           └──────────────────▶│  DexScreener API │
                               │  (Token Prices)  │
                               └──────────────────┘
```

### Token Detection Flow

1. **Fetch Native Balances**:
   - Base: ETH via Alchemy API
   - Solana: SOL via Alchemy API
   - Convert to USD using CoinGecko prices

2. **Fetch Token Holdings**:
   - Base ERC-20: Alchemy `alchemy_getTokenBalances` with top tokens
   - Query specific token contracts for balance
   - Get metadata (symbol, name, decimals)

3. **Price Discovery**:
   - Query DexScreener API per token address
   - Find highest liquidity pair on correct chain
   - Calculate USD value: `balance * price`
   - Filter out tokens with no price data

4. **Response Assembly**:
   - Combine native + token data
   - Calculate total portfolio value
   - Format for frontend consumption

## Wallets Monitored

| Network | Address |
|---------|---------|
| **Base** | `0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6` |
| **Solana** | `FeB1jqjCFKyQ2vVTPLgYmZu1yLvBWhsGoudP46fhhF8z` |

## API Reference

### Get Native Balances

```bash
curl https://arbi.betterfuturelabs.xyz/api/wallet/balances
```

**Response:**
```json
{
  "base": {
    "address": "0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6",
    "balance": 0.004471614096735506,
    "balanceFormatted": "0.0045",
    "usd": "11.18"
  },
  "solana": {
    "address": "FeB1jqjCFKyQ2vVTPLgYmZu1yLvBWhsGoudP46fhhF8z",
    "balance": 0.098995,
    "balanceFormatted": "0.0990",
    "usd": "9.90"
  },
  "timestamp": "2026-02-05T21:26:45.963Z"
}
```

### Get Token Holdings

```bash
curl https://arbi.betterfuturelabs.xyz/api/wallet/tokens
```

**Response:**
```json
{
  "tokens": [
    {
      "network": "base",
      "symbol": "USDC",
      "name": "USD Coin",
      "address": "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
      "balance": 10.05,
      "price": 0.9999,
      "priceChange24h": 0.02,
      "value": 10.05,
      "decimals": 6
    },
    {
      "network": "base",
      "symbol": "FT",
      "name": "Flying Tulip",
      "address": "0xa59f266b0947b25dc74571c8ae24b9905534a2d8",
      "balance": 100000,
      "price": 0.00000041,
      "priceChange24h": -5.32,
      "value": 0.041,
      "decimals": 18
    }
  ],
  "timestamp": "2026-02-05T21:26:45.963Z"
}
```

### Health Check

```bash
curl https://arbi.betterfuturelabs.xyz/api/wallet/health
```

**Response:**
```json
{
  "status": "ok",
  "timestamp": "2026-02-05T21:26:45.963Z",
  "alchemy_configured": true
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

## Integration with Unified Frontend

The Wallet Dashboard backend is integrated into the unified frontend at `/wallet`:

### Features
- **Total Balance Card**: Shows combined native + token value
- **Network Cards**: Base and Solana with native balances and USD values
- **Token Table**: Searchable list of all holdings with:
  - Network badges
  - Balance and price
  - 24h price change
  - USD value
- **Real-time Updates**: Auto-refresh every 30 seconds
- **Responsive Design**: Mobile-friendly layout

### API Proxying
All wallet API calls are proxied through the main domain:
```
https://arbi.betterfuturelabs.xyz/api/wallet/balances
https://arbi.betterfuturelabs.xyz/api/wallet/tokens
```

This avoids CORS issues and provides a unified API surface.

## USD Value Calculation

### Native Assets
- **ETH Price**: Fetched from CoinGecko API
- **SOL Price**: Fetched from CoinGecko API
- **Cache**: 5-minute TTL to avoid rate limits
- **Calculation**: `balance * price`

### ERC-20 Tokens
- **Price Source**: DexScreener API
- **Method**: Query by token address
- **Selection**: Highest liquidity pair on Base chain
- **Fallback**: If no price found, token is filtered out
- **Calculation**: `balance * priceUsd`

### Total Portfolio Value
```javascript
totalValue = baseNativeUsd + solanaNativeUsd + sum(tokenUsd)
```

Displayed on both:
- Main dashboard (wallet status card)
- Wallet page (total balance card)

## Token Filtering

To keep the UI clean, tokens are filtered by:

1. **Has Price Data**: Must have liquidity on DEX
2. **Non-Zero Balance**: Must hold > 0 tokens
3. **Valid Metadata**: Must have symbol and name

This prevents cluttering the UI with airdropped scam tokens or illiquid assets.

## Future Enhancements

- [x] ~~Price feeds (USD value)~~ ✅ Implemented
- [x] ~~Multi-chain support~~ ✅ Implemented (Base + Solana)
- [x] ~~Token holdings~~ ✅ Implemented (ERC-20 + SPL)
- [ ] Transaction history integration with onchain analytics
- [ ] Gas price tracking and estimation
- [ ] Multi-wallet support (track multiple addresses)
- [ ] Portfolio performance charts (historical value)
- [ ] Price alerts (notify on % change)
- [ ] Token swap integration (DEX aggregator)
- [ ] NFT holdings display
- [ ] Staking/yield tracking

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
