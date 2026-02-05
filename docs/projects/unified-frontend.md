# Unified Frontend

The unified frontend is a single-page application (SPA) that serves as the central dashboard for all Arbi services. It replaces the previous approach of separate subdomain sites with a cohesive, neobrutalist-designed interface.

## Overview

- **URL**: https://arbi.betterfuturelabs.xyz
- **Repository**: [Arbi-BFL/arbi-frontend](https://github.com/Arbi-BFL/arbi-frontend)
- **Port**: 3500
- **Tech Stack**: Vanilla JavaScript, HTML, CSS, Nginx

## Features

### Single-Page Architecture
- Client-side routing with hash-based navigation
- Routes: `/`, `/wallet`, `/email`, `/analytics`, `/onchain`
- No page reloads, seamless transitions between sections

### Neobrutalist Design System
- **Typography**: Space Grotesk (headings), Inter (body)
- **Colors**: Bold, high-contrast palette (yellow #FFD600, coral #FF6B6B, cyan #4ECDC4, purple #9B59B6)
- **Borders**: Thick 4px black borders on all cards
- **Shadows**: Flat 6px/8px shadows for depth
- **Background**: Soft purple-gray (#E8E5F0) for contrast
- **Text**: All card text is black for maximum readability

### Navigation
- Persistent black sidebar with yellow accents
- Service icons and labels
- Mobile-responsive hamburger menu
- Active state highlighting

### API Integration
All backend APIs are proxied through the main domain to avoid mixed content errors:

- `/api/wallet/*` → Wallet Dashboard Backend (port 3100)
- `/api/email/*` → Email Automation Backend (port 3400)
- `/api/analytics/*` → Analytics Dashboard Backend (port 3300)
- `/api/onchain/*` → Onchain Analytics Backend (port 8000)

### Smart Redirects
Old subdomain frontends redirect to unified paths:
- `wallet.arbi.betterfuturelabs.xyz` → `/wallet`
- `analytics.arbi.betterfuturelabs.xyz` → `/analytics`
- Backend APIs remain functional at their original endpoints

## Pages

### Dashboard (`/`)
Central overview showing:
- Total wallet balance (native + tokens)
- Email system status
- Onchain transaction count
- Analytics snapshots

### Wallet (`/wallet`)
Cryptocurrency portfolio management:
- **Total Balance Card**: Sum of all native + token holdings in USD
- **Network Cards**: Base and Solana native balances with USD values
- **Token Holdings**: ERC-20/SPL tokens with:
  - Network badges
  - Balance, price, 24h change
  - USD value per token
  - Total token value calculation
- **Search/Filter**: Find tokens by symbol, name, or address

### Email (`/email`)
Email monitoring and categorization:
- Total emails processed
- Last check timestamp
- System health status
- Recent email summaries with categories
- Discord integration for notifications

### Analytics (`/analytics`)
System performance metrics:
- Snapshots recorded
- System uptime tracking
- Historical data visualization

### Onchain (`/onchain`)
Blockchain transaction monitoring:
- Base and Solana transaction counts
- Recent transaction list with:
  - Network badges (Base/Solana)
  - Token symbols (ETH, SOL, USDC, FT, TULSA, etc.)
  - Transaction amounts
  - USD values (calculated in real-time)
  - Address display (shows `arbi.base.eth` for wallet addresses)
  - Status badges (confirmed/failed)
  - Block explorer links

## Development

### File Structure
```
public/
├── index.html          # Main HTML template
├── css/
│   └── style.css       # Neobrutalist styles
├── js/
│   ├── app.js          # Main application & router
│   ├── api.js          # API client functions
│   └── sections/
│       ├── dashboard.js
│       ├── wallet.js
│       ├── email.js
│       ├── analytics.js
│       └── onchain.js
└── assets/
    └── logo.png
```

### Adding a New Page
1. Create section file in `js/sections/`
2. Export `render{SectionName}()` function
3. Add route to `app.js` router
4. Add navigation link in sidebar
5. Create corresponding API functions in `api.js`

### Styling Guidelines
- Use CSS variables for colors (`--nb-yellow`, `--nb-coral`, etc.)
- All cards must have black text
- Use 4px borders and 6px shadows
- Maintain high contrast ratios
- Mobile-first responsive design

## Deployment

### Docker Setup
```yaml
version: '3.8'
services:
  frontend:
    image: nginx:alpine
    volumes:
      - ./public:/usr/share/nginx/html:ro
      - ./nginx.conf:/etc/nginx/conf.d/default.conf:ro
    ports:
      - "3500:80"
    restart: unless-stopped
```

### CI/CD Pipeline
GitHub Actions automatically:
1. Triggers on push to `main`
2. SSHs to server
3. Pulls latest code
4. Rebuilds Docker image
5. Restarts container
6. Prunes old images

### Nginx Configuration
- Serves static files from `/usr/share/nginx/html`
- Proxies `/api/*` requests to backend services
- GZIP compression enabled
- Custom error pages

## API Endpoints

### Wallet
- `GET /api/wallet/balances` - Native balances (Base ETH, Solana SOL) with USD
- `GET /api/wallet/tokens` - ERC-20/SPL tokens with prices

### Email
- `GET /api/email/stats` - Total processed, last check, status
- `GET /api/email/recent` - Recent emails with categories

### Analytics
- `GET /api/analytics/stats` - System metrics and snapshots

### Onchain
- `GET /api/onchain/stats` - Transaction counts by network
- `GET /api/onchain/transactions?limit=20` - Recent transactions with full details

## Future Enhancements

- [ ] Real-time WebSocket updates
- [ ] Dark mode toggle
- [ ] Customizable dashboard widgets
- [ ] Transaction filtering by network/token
- [ ] Portfolio performance charts
- [ ] Multi-wallet support
- [ ] Export transaction history (CSV/JSON)
