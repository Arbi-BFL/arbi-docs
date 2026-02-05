# Architecture

## System Overview

Arbi's infrastructure is a microservices architecture with a unified frontend, backend APIs, and blockchain integrations. All services are containerized, auto-deployed via GitHub Actions, and exposed through Nginx reverse proxy.

```
                    ┌─────────────────────────┐
                    │   Internet (HTTPS)      │
                    └───────────┬─────────────┘
                                │
                    ┌───────────▼──────────────┐
                    │  Nginx Reverse Proxy     │
                    │  SSL/TLS Termination     │
                    └───────────┬──────────────┘
                                │
                ┌───────────────┼───────────────┐
                │               │               │
        ┌───────▼────┐  ┌──────▼──────┐  ┌────▼─────┐
        │  Frontend  │  │  Backend    │  │  Docs    │
        │  (3500)    │  │  APIs       │  │  (3200)  │
        └────────────┘  └──────┬──────┘  └──────────┘
                                │
            ┌───────────────────┼───────────────────┐
            │                   │                   │
     ┌──────▼──────┐   ┌────────▼────────┐  ┌──────▼──────┐
     │  Wallet API │   │  Email API      │  │ Onchain API │
     │  (3100)     │   │  (3400)         │  │ (8000)      │
     └──────┬──────┘   └────────┬────────┘  └──────┬──────┘
            │                   │                   │
     ┌──────▼──────┐   ┌────────▼────────┐  ┌──────▼──────┐
     │  Alchemy    │   │  Gmail API      │  │  DexScreener│
     │  Base/SOL   │   │  (OAuth2)       │  │  (Prices)   │
     └─────────────┘   └─────────────────┘  └─────────────┘
```

## Core Components

### 1. Unified Frontend (Port 3500)
**Purpose**: Single-page application serving all UI components  
**Tech**: Vanilla JavaScript, HTML, CSS (neobrutalist design)  
**Routing**: Client-side hash routing (`/`, `/wallet`, `/email`, `/analytics`, `/onchain`)

**Why this approach:**
- Single deployment instead of 5 separate sites
- Consistent design system across all pages
- Unified API proxying (no CORS issues)
- Easier maintenance

### 2. Backend APIs
Each service runs as independent container with REST API:

| Service | Port | Purpose | External APIs |
|---------|------|---------|---------------|
| Wallet | 3100 | Portfolio tracking | Alchemy, DexScreener, CoinGecko |
| Email | 3400 | Email monitoring | Gmail API |
| Analytics | 3300 | System metrics | SQLite |
| Onchain | 8000 | Transaction monitoring | Alchemy, DexScreener |

**Design pattern**: Express.js + SQLite/in-memory storage + external API clients

### 3. Nginx Reverse Proxy
**Configuration**:
```nginx
location /api/wallet/ {
    proxy_pass http://localhost:3100/api/;
}
location /api/email/ {
    proxy_pass http://localhost:3400/api/;
}
location /api/onchain/ {
    proxy_pass http://localhost:8000/api/;
}
```

**Benefits**:
- Single SSL certificate for all services
- API proxying avoids CORS
- Easy service routing
- Health check endpoints

## Data Flow

### Wallet Balance Retrieval
```
1. Frontend → GET /api/wallet/balances
2. Nginx → Forward to localhost:3100
3. Wallet API → Alchemy API (Base & Solana balances)
4. Wallet API → CoinGecko (ETH & SOL prices)
5. Wallet API → Calculate USD values
6. Wallet API → Return JSON
7. Nginx → Forward response
8. Frontend → Display in UI
```

### Token Holdings
```
1. Frontend → GET /api/wallet/tokens
2. Wallet API → Alchemy getTokenBalances (Base)
3. Wallet API → For each token:
   - Query DexScreener for price
   - Filter by chain and liquidity
   - Calculate USD value
4. Wallet API → Return array of tokens
5. Frontend → Render table with search
```

### Transaction Monitoring
```
1. Background thread (5-min loop):
   - Alchemy getAssetTransfers (fromAddress)
   - Alchemy getAssetTransfers (toAddress)
   - Deduplicate by hash
   - Extract token symbol, amount
   - Query DexScreener for USD value
   - Store in SQLite
   - Send Discord notification
2. Frontend → GET /api/onchain/transactions
3. Onchain API → Query SQLite
4. Frontend → Display transaction list
```

## External Dependencies

### APIs
- **Alchemy**: Base & Solana RPC, transaction history
- **DexScreener**: Token price discovery (DEX liquidity)
- **CoinGecko**: Native token prices (ETH, SOL)
- **Gmail API**: OAuth2 email access
- **Discord Webhooks**: Real-time notifications

### Rate Limits
- Alchemy: 330 req/s (free tier) - no issue with 5-min polling
- DexScreener: No official limit, we don't hit it
- CoinGecko: 10-30 calls/min (free tier) - cached 5 minutes
- Gmail API: 250 quota units/user/second - no issue

## Storage

### SQLite Databases
- **Onchain**: `/data/onchain.db` - Transaction history
- **Email**: In-memory (stateless, Gmail is source of truth)
- **Analytics**: `/data/analytics.db` - System snapshots

**Why SQLite:**
- Embedded, no separate database server
- Perfect for read-heavy workloads
- Handles millions of rows easily
- Backs up with Docker volumes

### Docker Volumes
```yaml
volumes:
  - onchain-data:/data  # Persists SQLite DBs
  - gmail-data:/data    # Persists OAuth token
```

## Security Model

### Credentials
- Stored in `/root/.openclaw/workspace/.credentials` (not in git)
- Injected as environment variables in Docker
- Gmail OAuth token in Docker volume (writable)

### API Keys
- **Alchemy**: Read-only RPC access
- **Gmail**: Read-only OAuth scope
- **Discord**: Webhook URLs (write-only)

### Private Keys
- Base wallet private key: Not used in backend services (sign transactions manually)
- Solana wallet private key: Not used in backend services

**Philosophy**: Services only READ blockchain/email data, never sign/send transactions autonomously.

## Deployment Model

### CI/CD Pipeline
```
Push to main → GitHub Actions → SSH to server → 
Pull code → Docker build → Docker up -d → Health check
```

### Zero-Downtime Updates
- Docker containers restart individually
- Nginx keeps serving during restarts
- Frontend cached by browser
- APIs respond within 30s of restart

### Rollback Strategy
```bash
# View recent images
docker images | grep arbi

# Roll back to previous image
docker stop arbi-frontend
docker run -d --name arbi-frontend <old-image-id>
```

## Design Decisions

### Why Unified Frontend?
**Problem**: 5 separate subdomain sites meant:
- 5 separate deployments
- 5 SSL certificates
- Inconsistent design
- CORS issues

**Solution**: Single SPA with client-side routing
- 1 deployment
- 1 SSL cert
- Unified neobrutalist design
- API proxying via Nginx

### Why Backend-First Architecture?
**Problem**: Direct blockchain RPC calls from browser:
- CORS issues with public RPCs
- API keys exposed in frontend
- Slow response times

**Solution**: Backend APIs fetch data server-side
- Proxy requests through Nginx
- Cache responses
- Hide API keys
- Process data before returning

### Why Polling Instead of Webhooks?
**Problem**: Blockchain data changes constantly

**Solution**: 5-minute polling loop
- Simple to implement
- Stays within rate limits
- Easy to debug
- Reliable (no webhook failures)

### Why SQLite Instead of PostgreSQL?
**Problem**: Need persistent transaction history

**Solution**: SQLite embedded database
- No separate database server
- Perfect for read-heavy workloads
- Backs up with Docker volumes
- Handles 1M+ rows easily

## Scaling Considerations

### Current Load
- ~50 requests/hour to APIs
- ~100 blockchain queries/hour
- 2 new transactions per day (avg)
- 5-10 emails per day

**Bottlenecks**: None. Current architecture overkill for load.

### If Scaling Needed
1. **Multiple wallets**: Add Redis cache for balances
2. **High transaction volume**: Switch to PostgreSQL
3. **Many users**: Add API authentication
4. **Global deployment**: Use CDN for frontend

But current setup handles 100x load easily.
