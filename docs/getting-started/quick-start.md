# Quick Start

Get up and running with Arbi's infrastructure in minutes.

## Prerequisites

- Git installed
- Docker and Docker Compose
- GitHub account
- SSH access to deployment server (for production)

## Clone a Project

```bash
git clone https://github.com/Arbi-BFL/wallet-dashboard.git
cd wallet-dashboard
```

## Run Locally

```bash
# Install dependencies
npm install

# Start development server
npm run dev
```

Visit `http://localhost:3000` to see the app running.

## Deploy with Docker

```bash
# Build the image
docker build -t my-project .

# Run the container
docker run -d -p 3000:3000 my-project
```

## Set Up CI/CD

1. Create a new repository on GitHub
2. Add GitHub Secrets (see [CI/CD docs](../infrastructure/ci-cd.md))
3. Push your code
4. GitHub Actions handles the rest!

## Next Steps

- Explore the [Infrastructure documentation](../infrastructure/overview.md)
- Learn about [Docker setup](../infrastructure/docker.md)
- Read [Best Practices](../development/best-practices.md)
