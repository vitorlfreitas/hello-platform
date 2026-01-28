# Docker

## Overview

Docker is used to build and run the hello-platform application as a containerized image. The project uses a **multi-stage build** to keep the final image small and secure:

1. **Builder stage** — Installs dependencies and compiles TypeScript into JavaScript (`dist/`).
2. **Production stage** — Copies only the compiled output and production dependencies into a minimal Node.js Alpine image. Runs as a non-root user (`nodejs:1001`) for security.

The resulting image exposes port `3000` and includes a built-in health check against the `/health` endpoint.

A `docker-compose.yaml` is also provided for local development with automatic restart and health monitoring.

## Getting Started

### Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running

### Build the Image

```bash
docker build -t hello-platform:latest .
```

### Run the Container

```bash
docker run -d -p 3000:3000 --name hello-platform hello-platform:latest
```

### Verify It Works

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{ "status": "ok", "timestamp": "...", "uptime": "..." }
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `docker build -t hello-platform:latest .` | Build the image |
| `docker run -d -p 3000:3000 --name hello-platform hello-platform:latest` | Run in detached mode |
| `docker logs -f hello-platform` | Follow container logs |
| `docker stop hello-platform` | Stop the container |
| `docker rm hello-platform` | Remove the container |
| `docker images hello-platform` | List built images |

### Using Docker Compose

| Command | Purpose |
|---------|---------|
| `docker-compose up -d` | Build and start the service |
| `docker-compose logs -f` | Follow logs |
| `docker-compose down` | Stop and remove the container |
| `docker-compose up -d --force-recreate` | Recreate the container (useful after config changes) |

## Troubleshooting

### Port 3000 already in use

Another process is binding port 3000. Map to a different host port:

```bash
docker run -d -p 8080:3000 --name hello-platform hello-platform:latest
```

### Container starts but health check fails

Check the logs for errors:

```bash
docker logs -f hello-platform
```

If the container exits immediately, inspect it:

```bash
docker inspect hello-platform --format='{{.State}}'
```

### Image not found after build

Verify the image was tagged correctly:

```bash
docker images | grep hello-platform
```

If missing, rebuild:

```bash
docker build -t hello-platform:latest .
```

### Docker Compose "image not found"

The compose file builds from source. If you modified code, rebuild:

```bash
docker-compose build
docker-compose up -d
```
