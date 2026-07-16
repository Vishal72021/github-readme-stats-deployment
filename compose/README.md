# Docker Compose

This directory contains Docker Compose configurations for different environments.

## Files

| File | Purpose |
|------|---------|
| docker-compose.dev.yml | Local development environment |
| docker-compose.prod.yml | Production deployment |

## Usage

Development:

```bash
docker compose -f compose/docker-compose.dev.yml up --build
```

---

# Staff Engineer Review

A couple of notes about this design:

1. **Logging**: Adding log rotation (`max-size`, `max-file`) in production is a good operational practice and prevents logs from growing indefinitely.

2. **Networks**: Using separate named bridge networks for development and production keeps environments isolated and prepares us for adding Nginx, monitoring, or other services later.

3. **Resource limits**: I intentionally did **not** include `deploy.resources`. Those settings are primarily for Docker Swarm and are ignored by the standard `docker compose` CLI. If we later target Kubernetes or Swarm, we'll introduce resource constraints in the appropriate manifests rather than giving the impression they're enforced locally.

---

## Commit

**Run from:**

```text
D:\Projects\github-stats-platform