# Docker

This directory contains the containerization assets for the deployment platform.

## Files

| File | Purpose |
|------|---------|
| Dockerfile | Builds the deployment image |
| entrypoint.sh | Container startup script |
| healthcheck.sh | Container health validation |
| .dockerignore | Build context exclusions |

## Design Principles

- Production-first
- Reproducible builds
- Minimal runtime image
- Version-pinned upstream source
- Environment-driven configuration