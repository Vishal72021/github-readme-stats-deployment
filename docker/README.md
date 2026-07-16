# Docker

This directory contains the containerization assets used by GitHub Stats Platform.

The project follows a Docker-first development approach with separate configurations for development and production environments.

---

## Directory Structure

| File | Purpose |
|------|---------|
| Dockerfile.dev | Development container configuration |
| Dockerfile.prod | Production-ready container configuration |
| healthcheck.sh | Container health validation |
| README.md | Docker documentation |

---

## Design Principles

- Production-first configuration
- Reproducible builds
- Secure container practices
- Minimal runtime footprint
- Environment-based configuration
- Easy local development

---

## Container Strategy

GitHub Stats Platform is an infrastructure project.

The Docker assets in this directory provide a consistent and reproducible deployment strategy while remaining flexible enough to support future customizations and production deployments.

Docker Compose orchestrates the services, while the Dockerfiles define how the application is built and packaged.

---

## Related Documentation

- `docs/deployment/docker.md`
- `docs/deployment/local-development.md`
- `compose/docker-compose.dev.yml`
- `compose/docker-compose.prod.yml`