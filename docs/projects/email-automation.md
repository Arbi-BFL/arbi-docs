# Email Automation

Intelligent email monitoring, categorization, and notification system integrated with Discord for real-time alerts.

## Overview

- **URL**: https://arbi.betterfuturelabs.xyz/email
- **Repository**: [Arbi-BFL/email-automation](https://github.com/Arbi-BFL/email-automation)
- **Port**: 3400
- **Tech Stack**: Python, Flask, Gmail API, Discord Webhooks

## Features

### Gmail Integration
- OAuth2 authentication with Gmail API
- Read-only access to inbox
- Processes unread emails automatically
- Marks emails as read after processing
- 5-minute polling interval

### Intelligent Categorization
Emails are automatically categorized using keyword matching:

| Category | Keywords | Priority |
|----------|----------|----------|
| **security** | password, 2fa, verification, suspicious | 1 (highest) |
| **urgent** | urgent, asap, important, action required | 2 |
| **social** | linkedin, twitter, facebook, instagram | 3 |
| **newsletter** | newsletter, unsubscribe, weekly digest | 4 |
| **marketing** | promotion, sale, discount, offer | 5 |
| **notification** | notification, alert, reminder, update | 6 |
| **general** | (default fallback) | 7 (lowest) |

### Discord Notifications
Real-time alerts sent to Discord channel with:
- **Color-coded embeds** based on category
- **Direct mention** of Arbi (@REDACTED_USER_ID) for automatic investigation
- Sender information (name and email)
- Subject line
- Email preview (first 200 characters)
- Category badge
- Timestamp

### API Endpoints
- `GET /api/stats` - Email processing statistics
- `GET /api/recent` - Recent emails with categories
- `GET /health` - System health check

## Architecture

### Authentication Flow
1. Initial setup: Run `gmail_auth.py` to generate OAuth token
2. Browser opens for Google account authorization
3. Token saved to `/data/gmail_token.json`
4. Flask service loads token on startup
5. Token automatically refreshed when expired

### Processing Workflow
1. **Polling Loop** (every 5 minutes):
   - Fetches unread emails via Gmail API
   - Extracts sender, subject, body preview
   - Categorizes based on content
   - Sends Discord notification with mention
   - Marks email as read
   - Updates statistics

2. **Categorization Logic**:
   - Checks subject and body for category keywords
   - Priority-based matching (security > urgent > social, etc.)
   - Falls back to "general" if no keywords match
   - Case-insensitive matching

3. **Discord Integration**:
   - Color-coded embeds for visual recognition
   - Mentions Arbi for automatic follow-up
   - Embed fields: From, Subject, Preview, Category
   - Error handling with fallback messages

## Configuration

### Environment Variables
```bash
DISCORD_WEBHOOK=https://discord.com/api/webhooks/REDACTED_WEBHOOK/...
GMAIL_TOKEN_PATH=/data/gmail_token.json
GMAIL_CREDENTIALS_PATH=/app/gmail_credentials.json
```

### Gmail API Setup
1. Create project in Google Cloud Console
2. Enable Gmail API
3. Create OAuth 2.0 credentials (Desktop app)
4. Download `gmail_credentials.json`
5. Run `gmail_auth.py` to authorize
6. Token stored in `/data/gmail_token.json`

### Discord Webhook Setup
1. Go to Discord channel settings
2. Integrations → Webhooks → New Webhook
3. Copy webhook URL
4. Set as `DISCORD_WEBHOOK` environment variable

## API Reference

### GET /api/stats
Returns email processing statistics:
```json
{
  "total_processed": 27,
  "last_check": "2026-02-05T21:34:15Z",
  "status": "healthy"
}
```

### GET /api/recent?limit=10
Returns recent emails with categories:
```json
{
  "emails": [
    {
      "id": "18d9f...",
      "from": "sender@example.com",
      "subject": "Important update",
      "preview": "Hi Arbi, we wanted to let you know...",
      "category": "urgent",
      "timestamp": "2026-02-05T21:30:00Z",
      "read": true
    }
  ]
}
```

### GET /health
Health check endpoint:
```json
{
  "status": "healthy",
  "gmail_authenticated": true,
  "discord_configured": true,
  "last_check": "2026-02-05T21:34:15Z"
}
```

## Discord Embed Colors

Category-specific colors for visual recognition:

| Category | Color (Hex) | Color Name |
|----------|-------------|------------|
| security | #E74C3C | Red |
| urgent | #FF6B6B | Coral |
| social | #3498DB | Blue |
| newsletter | #9B59B6 | Purple |
| marketing | #FFD600 | Yellow |
| notification | #4ECDC4 | Cyan |
| general | #95A5A6 | Gray |

## Deployment

### Docker Setup
```yaml
version: '3.8'
services:
  email-automation:
    build: .
    ports:
      - "3400:3400"
    volumes:
      - gmail-data:/data
    environment:
      - DISCORD_WEBHOOK=${DISCORD_WEBHOOK}
    restart: unless-stopped
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3400/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  gmail-data:
```

### Initial Token Generation
```bash
# On server, run authentication script
docker exec -it email-automation python gmail_auth.py

# Follow browser prompt to authorize
# Token saved to /data/gmail_token.json
# Restart container to load token
docker restart email-automation
```

## Category Examples

### Security Emails
- "Your password has been changed"
- "New 2FA verification code"
- "Suspicious login detected"
- "Security alert for your account"

### Urgent Emails
- "Action required: Invoice overdue"
- "URGENT: Server down"
- "Important: Meeting rescheduled ASAP"

### Social Emails
- "New LinkedIn connection request"
- "Someone mentioned you on Twitter"
- "Facebook friend suggestion"

### Newsletter Emails
- "Weekly digest from Medium"
- "Your newsletter from Substack"
- "Tech news roundup"

### Marketing Emails
- "50% off sale this weekend"
- "Exclusive promotion for you"
- "Limited time discount"

### Notification Emails
- "Your package has shipped"
- "Reminder: Event tomorrow"
- "Update: New features available"

## Error Handling

### Gmail API Errors
- **Token expired**: Automatically refreshed
- **Rate limit**: Logged and retried next cycle
- **Network failure**: Logged with error details

### Discord Webhook Errors
- **Invalid webhook**: Logged, notifications skipped
- **Rate limit**: Queued for next attempt
- **Network failure**: Logged with retry

### Category Matching
- **No keywords match**: Falls back to "general" category
- **Multiple matches**: Uses highest priority category
- **KeyError**: Fixed by adding "general" to CATEGORIES dict

## OpenClaw Integration

The email automation system is integrated with OpenClaw Gateway:

### Channel Configuration
```json
{
  "channels": {
    "discord": [
      {
        "id": "1468851464960082054",
        "label": "email-notifications",
        "guild": "1468733826963476746"
      }
    ]
  }
}
```

### Automatic Response
When email notification appears in #inbox channel:
1. OpenClaw detects mention of Arbi
2. Message includes email details (sender, subject, preview)
3. Arbi can investigate and respond directly
4. Context preserved in Discord thread

## Statistics Tracking

### Tracked Metrics
- **Total processed**: Cumulative count of all processed emails
- **Last check**: Timestamp of most recent polling cycle
- **System status**: healthy/error
- **Category distribution**: Count per category (future)
- **Processing time**: Average time per email (future)

### Database Schema (Future)
```sql
CREATE TABLE emails (
  id TEXT PRIMARY KEY,
  from_email TEXT,
  from_name TEXT,
  subject TEXT,
  preview TEXT,
  category TEXT,
  timestamp INTEGER,
  read BOOLEAN,
  notified BOOLEAN
)
```

## Future Enhancements

- [ ] SQLite database for email history
- [ ] Full-text search across emails
- [ ] Custom category rules (user-defined keywords)
- [ ] Email reply automation for common queries
- [ ] Attachment detection and download
- [ ] Spam filtering with ML
- [ ] Multi-account support
- [ ] Email templates for responses
- [ ] Analytics dashboard (emails per day, category breakdown)
- [ ] Integration with calendar for meeting invites
