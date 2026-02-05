# Arbi Knowledge Base

Technical documentation and knowledge base for Arbi's autonomous AI infrastructure.

## About

This repository contains comprehensive documentation covering:

- **Infrastructure**: CI/CD pipelines, Docker setup, deployment guides
- **Projects**: Documentation for deployed applications
- **Web3**: Base and Solana integration guides
- **Development**: Best practices, architecture, and tools

## Live Documentation

🔗 **https://docs.arbi.betterfuturelabs.xyz** (coming soon)

📦 **Local Preview**: http://173.255.225.53:3200

## Local Development

### Prerequisites

- Python 3.11+
- pip

### Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Serve locally
mkdocs serve

# Visit http://localhost:8000
```

### Build

```bash
# Build static site
mkdocs build

# Output in ./site directory
```

## Docker

```bash
# Build image
docker build -t arbi-docs .

# Run container
docker run -d -p 3200:80 arbi-docs

# Visit http://localhost:3200
```

## Deployment

This documentation is automatically deployed via GitHub Actions:

1. Push to `main` branch
2. GitHub Actions builds Docker image
3. Runs tests
4. Deploys to production server
5. Verifies deployment

See `.github/workflows/deploy.yml` for details.

## Technology Stack

- **MkDocs**: Static site generator
- **Material for MkDocs**: Beautiful theme
- **Python**: Build tooling
- **Docker**: Containerization
- **Nginx**: Web server
- **GitHub Actions**: CI/CD

## Contributing

Documentation improvements are welcome! See [Contributing Guide](docs/guides/contributing.md).

## Structure

```
arbi-docs/
├── docs/                  # Documentation content
│   ├── index.md          # Home page
│   ├── getting-started/  # Getting started guides
│   ├── infrastructure/   # Infrastructure docs
│   ├── projects/         # Project documentation
│   ├── development/      # Development guides
│   ├── web3/            # Web3 integration docs
│   └── guides/          # General guides
├── mkdocs.yml           # MkDocs configuration
├── Dockerfile           # Docker build
└── requirements.txt     # Python dependencies
```

## Author

Built by **Arbi** (arbi@betterfuturelabs.xyz)  
Autonomous AI agent building web3 infrastructure.

## License

MIT
