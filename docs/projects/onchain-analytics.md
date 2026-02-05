# Onchain Analytics

Real-time blockchain transaction monitoring for Arbi's Base and Solana wallets with USD value calculation and Discord notifications.

## Overview

- **URL**: https://arbi.betterfuturelabs.xyz/onchain
- **Direct URL**: https://data.betterfuturelabs.xyz
- **Repository**: [Arbi-BFL/onchain-analytics](https://github.com/Arbi-BFL/onchain-analytics)
- **Port**: 8000
- **Tech Stack**: Python, Flask, SQLite, Alchemy API, DexScreener API

## Features

### Multi-Chain Monitoring
- **Base (Layer 2)**: Tracks ETH and ERC-20 token transfers
- **Solana**: Tracks SOL and SPL token transfers
- Monitors both incoming and outgoing transactions
- 5-minute polling interval

### Transaction Details
Each transaction record includes:
- Transaction hash
- Network (Base or Solana)
- From/To addresses (displays `arbi.base.eth` for Arbi's wallets)
- Token symbol (ETH, SOL, USDC, FT, TULSA, etc.)
- Token amount
- USD value (calculated in real-time)
- Block number
- Timestamp
- Status (confirmed/failed)

### USD Value Calculation

#### Native Tokens (ETH, SOL)
- Fetched from CoinGecko API
- 5-minute cache to avoid rate limits
- Real-time price updates

#### ERC-20 Tokens
- Fetched from DexScreener API per token address
- Finds highest liquidity pair on correct chain
- Supports any token with DEX liquidity

### Discord Notifications
Sends real-time alerts to Discord webhook on new transactions:
- Network emoji (🔵 Base, 🟣 Solana)
- From/To addresses (truncated)
- Transaction value with token symbol
- Direct link to block explorer

### Block Explorer Integration
- **Base**: BaseScan links for all Base transactions
- **Solana**: Solana Explorer links for all Solana transactions
- One-click transaction verification

## Architecture

### Database Schema

#### Transactions Table
```sql
CREATE TABLE transactions (
  hash TEXT PRIMARY KEY,
  network TEXT,
  from_address TEXT,
  to_address TEXT,
  value TEXT,
  timestamp INTEGER,
  block_number INTEGER,
  status TEXT,
  gas_used TEXT,
  notified INTEGER DEFAULT 0,
  token_symbol TEXT,
  token_address TEXT,
  usd_value TEXT
)
```

#### Activity Snapshots Table
```sql
CREATE TABLE activity_snapshots (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  timestamp INTEGER,
  network TEXT,
  transaction_count INTEGER,
  total_value TEXT
)
```

### Data Flow

1. **Monitoring Thread** (background, 5-minute loop):
   - Fetches Base transactions via Alchemy API
   - Fetches Solana transactions via Alchemy API
   - Processes and stores new transactions
   - Calculates USD values
   - Sends Discord notifications
   - Records activity snapshots

2. **API Endpoints** (Flask):
   - Serves transaction data to frontend
   - Provides statistics and filtering
   - Health check endpoint

## Alchemy API Integration

### Base (Ethereum L2)
Uses `alchemy_getAssetTransfers` method:
```python
{
  "method": "alchemy_getAssetTransfers",
  "params": [{
    "fromBlock": "0x0",
    "toBlock": "latest",
    "fromAddress": "0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6",
    "toAddress": "0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6",
    "category": ["external", "erc20", "erc721", "erc1155"],
    "withMetadata": true
  }]
}
```

**Important**: Must query both `fromAddress` AND `toAddress` to catch all transactions. Results are deduplicated by hash.

### Solana
Two-step process:
1. `getSignaturesForAddress` - Get transaction signatures
2. `getTransaction` - Fetch full details for each signature

Parses account keys and balance changes to extract:
- From/To addresses
- SOL transfer amounts
- Transaction metadata

## API Endpoints

### GET /api/stats
Returns overall statistics:
```json
{
  "total_transactions": 23,
  "base_transactions": 21,
  "solana_transactions": 2,
  "recent_24h": 8,
  "total_value_eth": 12.34
}
```

### GET /api/transactions?limit=20
Returns recent transactions:
```json
[
  {
    "hash": "0xae4ce0b...",
    "network": "base",
    "from_address": "0xa59f266b...",
    "to_address": "0x75f39d9b...",
    "value": "9.0",
    "token_symbol": "FT",
    "token_address": "0xa59f266b...",
    "usd_value": "0.0000037",
    "timestamp": 1738789899,
    "block_number": 41736476,
    "status": "confirmed"
  }
]
```

### GET /api/activity?hours=24
Returns activity snapshots for charts.

### GET /health
Health check endpoint:
```json
{
  "status": "healthy",
  "timestamp": 1738789899,
  "alchemy_configured": true,
  "discord_configured": true
}
```

## Configuration

### Environment Variables
```bash
ALCHEMY_API_KEY=REDACTED_API_KEY
DISCORD_WEBHOOK=https://discord.com/api/webhooks/...
```

### Monitored Wallets
- **Base**: `0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6` (arbi.base.eth)
- **Solana**: `FeB1jqjCFKyQ2vVTPLgYmZu1yLvBWhsGoudP46fhhF8z`

## Deployment

### Docker Compose
```yaml
version: '3.8'
services:
  onchain-analytics:
    build: .
    ports:
      - "8000:8000"
    volumes:
      - onchain-data:/data
    environment:
      - ALCHEMY_API_KEY=${ALCHEMY_API_KEY}
      - DISCORD_WEBHOOK=${DISCORD_WEBHOOK}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  onchain-data:
```

### Data Persistence
SQLite database stored in Docker volume at `/data/onchain.db`.

## Technical Challenges & Solutions

### Challenge: Base L2 "Internal" Category
**Problem**: Alchemy's `internal` transaction category is not supported on Base L2.  
**Solution**: Exclude `internal` from category list, use only `external`, `erc20`, `erc721`, `erc1155`.

### Challenge: Missing Transactions
**Problem**: Only querying `fromAddress` missed incoming transactions.  
**Solution**: Query both `fromAddress` AND `toAddress`, then deduplicate by hash.

### Challenge: Solana Transaction Parsing
**Problem**: `getSignaturesForAddress` only returns signatures, not full transaction details.  
**Solution**: Fetch each signature with `getTransaction` using `jsonParsed` encoding, then parse account keys and balance changes to extract from/to/amount.

### Challenge: Token USD Values
**Problem**: DexScreener may return multiple pairs for a token.  
**Solution**: Filter by chain ID and select pair with highest liquidity.

## Monitoring Best Practices

### Rate Limits
- Alchemy: 330 requests/second (free tier)
- DexScreener: No official limit, but recommend caching
- CoinGecko: 10-30 calls/minute (free tier)

Our 5-minute polling interval stays well within limits.

### Error Handling
- Network failures: Logged and retried next cycle
- Missing prices: Falls back to 0, logs error
- API errors: Logged with full error details

### Database Maintenance
- Indexes on `network`, `timestamp` for fast queries
- Consider archiving old transactions after 90 days
- SQLite handles up to ~1M transactions easily

## Future Enhancements

- [ ] Token approval monitoring
- [ ] NFT transfer detection (ERC-721, ERC-1155)
- [ ] Multi-sig wallet support
- [ ] Transaction categorization (swap, transfer, mint, burn)
- [ ] Gas price alerts
- [ ] Historical charts (daily volume, transaction count)
- [ ] Webhook alerts for large transactions
- [ ] CSV export for tax reporting
