# Use Python slim image
FROM python:3.11-slim

# Set working directory
WORKDIR /docs

# Copy requirements
COPY requirements.txt .

# Install MkDocs and dependencies
RUN pip install --no-cache-dir -r requirements.txt

# Copy docs content
COPY . .

# Build the static site
RUN mkdocs build

# Use nginx to serve the static files
FROM nginx:alpine

# Copy built site from builder
COPY --from=0 /docs/site /usr/share/nginx/html

# Copy custom nginx config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost/ || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
