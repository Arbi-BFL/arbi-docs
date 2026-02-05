# Best Practices

Lessons learned from building and deploying Arbi's infrastructure.

## Docker

### Health Checks Are Mandatory
**Always include health check in Dockerfile:**
```dockerfile
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:8000/health || exit 1
```

**Why**: Docker can auto-restart unhealthy containers. Nginx can route around them.

### Build Cache Issues
**Problem**: Sometimes Docker build cache prevents file updates from being copied.

**Solution**: 
```bash
# When build cache causes issues
docker cp /path/to/updated/file.js container:/app/file.js
docker restart container

# Or force no-cache build
docker build --no-cache -t image-name .
```

### Volume Permissions
**Problem**: SQLite database gets created as root, can't be written by app.

**Solution**: Use Docker volumes, not bind mounts:
```yaml
volumes:
  - onchain-data:/data  # Good: Docker manages permissions
  # NOT: ./data:/data  # Bad: Host permissions conflict
```

## API Design

### Backend > Direct Blockchain Calls
**Don't**: Call blockchain RPCs directly from frontend
```javascript
// Bad: CORS issues, exposed keys, slow
const provider = new ethers.JsonRpcProvider(PUBLIC_RPC);
```

**Do**: Proxy through backend API
```javascript
// Good: Server-side fetch, cached, secure
const response = await fetch('/api/wallet/balances');
```

### Cache Expensive Calls
**DexScreener price lookups are slow.** Cache them:
```python
price_cache = {}
price_cache_time = 0

def get_token_price(address):
    if time.time() - price_cache_time < 300:  # 5-min cache
        return price_cache.get(address, 0)
    # ... fetch and update cache
```

### Health Check Endpoints
Every service needs `/health`:
```python
@app.route('/health')
def health():
    return jsonify({
        'status': 'healthy',
        'timestamp': int(time.time()),
        'external_apis_configured': check_api_keys()
    })
```

## Blockchain

### Base L2 Quirks
**Problem**: Alchemy's `internal` transaction category doesn't work on Base L2.

**Solution**: Exclude it from category list:
```python
"category": ["external", "erc20", "erc721", "erc1155"]
# NOT: ["external", "internal", "erc20", ...]
```

### Query Both Directions
**Problem**: Only querying `fromAddress` misses incoming transactions.

**Solution**: Query both, then deduplicate:
```python
# Outgoing
outgoing = alchemy_getAssetTransfers(fromAddress=wallet)

# Incoming
incoming = alchemy_getAssetTransfers(toAddress=wallet)

# Deduplicate by hash
all_txs = deduplicate_by_hash(outgoing + incoming)
```

### Solana Transaction Parsing
**Problem**: `getSignaturesForAddress` only returns signatures, not full details.

**Solution**: Two-step fetch:
```python
# Step 1: Get signatures
sigs = getSignaturesForAddress(wallet, limit=50)

# Step 2: Fetch full details for each
for sig in sigs:
    tx = getTransaction(sig, encoding="jsonParsed")
    parse_balance_changes(tx)
```

### Token Address Display
**Replace your wallet address with basename:**
```javascript
function formatAddress(addr) {
    const WALLET = '0x75f39d9Bff76d376F3960028d98F324aAbB6c5e6';
    if (addr.toLowerCase() === WALLET.toLowerCase()) {
        return 'arbi.base.eth';
    }
    return `${addr.slice(0,10)}...${addr.slice(-8)}`;
}
```

## Frontend

### Neobrutalist Design Consistency
**Colors**: Define CSS variables, use everywhere
```css
:root {
    --nb-yellow: #FFD600;
    --nb-coral: #FF6B6B;
    --nb-black: #1A1A1A;
}
```

**All card text must be black:**
```javascript
// Even if background is colored
style="color: var(--nb-black);"
```

**Borders and shadows:**
```css
border: 4px solid var(--nb-black);
box-shadow: 6px 6px 0 var(--nb-black);
```

### Client-Side Routing
**Hash-based routing is simple:**
```javascript
window.addEventListener('hashchange', router);
function router() {
    const page = window.location.hash.slice(1) || '';
    if (page === 'wallet') renderWallet();
    else if (page === 'email') renderEmail();
    // ...
}
```

**No server-side routing needed.** Single `index.html` serves all routes.

### API Error Handling
**Always handle API failures gracefully:**
```javascript
try {
    const data = await fetch('/api/wallet/balances').then(r => r.json());
    updateUI(data);
} catch (error) {
    console.error('Fetch failed:', error);
    displayError('Unable to load balances');
}
```

## Email Processing

### Category Fallback
**Problem**: KeyError when email doesn't match any category.

**Solution**: Always have a default category:
```python
CATEGORIES = {
    'security': {...},
    'urgent': {...},
    'general': {...}  # REQUIRED: fallback
}

category = determine_category(email) or 'general'
```

### Mention for Auto-Investigation
**Tag Arbi in Discord notifications:**
```python
webhook_payload = {
    "content": "<@YOUR_USER_ID_HERE>",  # Arbi's user ID
    "embeds": [email_embed]
}
```

**Why**: OpenClaw sees the mention and automatically investigates.

## CI/CD

### SSH Secrets Required
**GitHub Actions needs SSH access to deploy:**
```bash
gh secret set SSH_HOST --body "173.255.225.53"
gh secret set SSH_USERNAME --body "root"
gh secret set SSH_KEY < ~/.ssh/id_ed25519
```

**Without these, deployment silently fails.**

### Restart > Rebuild
**When updating single file:**
```bash
# Fast: Copy file + restart
docker cp app.py container:/app/app.py
docker restart container

# Slow: Full rebuild
docker-compose down && docker-compose build && docker-compose up -d
```

### Health Check After Deploy
**Always verify deployment succeeded:**
```bash
curl https://arbi.betterfuturelabs.xyz/api/wallet/health
```

If health check fails, rollback immediately.

## Security

### Never Commit Credentials
```gitignore
.credentials
gmail_credentials.json
gmail_token.json
.env
*.pem
*.key
```

### Read-Only API Scopes
- **Gmail**: `gmail.readonly` scope only
- **Alchemy**: No authentication required (public RPC)
- **Discord**: Write-only webhooks (can't read messages)

### Private Keys Stay Local
**Never deploy private keys to servers.** Sign transactions manually on local machine, broadcast signed transaction.

## Monitoring

### Discord > Logs
**Logs get lost. Discord persists.**

Send notifications for:
- New transactions (with USD value)
- New emails (with category)
- System errors (with stack trace)

### Timestamps Matter
**Always include timestamps in responses:**
```json
{
    "data": {...},
    "timestamp": "2026-02-05T21:26:45.963Z"
}
```

Helps debug "when did this data get fetched?"

### Health Checks Everywhere
```bash
curl https://arbi.betterfuturelabs.xyz/api/wallet/health
curl https://arbi.betterfuturelabs.xyz/api/email/health
curl https://arbi.betterfuturelabs.xyz/api/onchain/health
```

One command to check everything is working.

## Database

### SQLite Indexes
**Always index columns you query on:**
```sql
CREATE INDEX idx_timestamp ON transactions(timestamp);
CREATE INDEX idx_network ON transactions(network);
```

### Deduplication
**Always deduplicate before inserting:**
```python
# Check if exists first
cursor.execute('SELECT hash FROM transactions WHERE hash = ?', (tx_hash,))
if cursor.fetchone():
    return  # Already exists
```

### Type Coercion
**SQLite stores everything as text. Cast when querying:**
```sql
SELECT SUM(CAST(value AS REAL)) FROM transactions
```

## Common Pitfalls

### CORS Issues
**Symptom**: Frontend can't fetch from backend.

**Cause**: Missing CORS headers or wrong origin.

**Fix**: Proxy through Nginx:
```nginx
location /api/wallet/ {
    proxy_pass http://localhost:3100/api/;
}
```

### Mixed Content Errors
**Symptom**: HTTPS page can't fetch from HTTP API.

**Cause**: Frontend on HTTPS, API on HTTP.

**Fix**: Proxy through main domain (HTTPS everywhere).

### Rate Limits
**Symptom**: CoinGecko returns 429 Too Many Requests.

**Cause**: Calling API too frequently.

**Fix**: Cache responses for 5 minutes.

### Stale Docker Cache
**Symptom**: Code changes not reflected in container.

**Cause**: Docker cached old layers.

**Fix**: Use `docker cp` or `--no-cache` flag.

## Testing

### Manual Testing Checklist
Before deploying:
- [ ] Health check returns 200
- [ ] API returns valid JSON
- [ ] Frontend displays data correctly
- [ ] No console errors
- [ ] Mobile responsive
- [ ] All links work

### Rollback Plan
**Always test rollback before needing it:**
```bash
# Tag current version
docker tag arbi-frontend:latest arbi-frontend:v1.0

# Deploy new version
docker build -t arbi-frontend:latest .

# If it breaks, rollback
docker run -d arbi-frontend:v1.0
```

## Documentation

### Document WHY, Not What
**Bad**: "This function fetches token prices."

**Good**: "We fetch prices from DexScreener because CoinGecko doesn't list small-cap tokens, and we need to filter by chain to avoid wrong prices."

### Update Docs Immediately
**Not later. Now.** Future you will forget the context.

### Examples > Explanations
Show actual API response. Show actual code. Show actual commands.

Don't describe what to do. Show how to do it.
