# Compose
Placeholder.
# Docker Compose

This directory contains the Docker Compose configuration used to orchestrate
the GitHub Readme Stats application container.

The Compose layer connects the Docker image definition, runtime environment
configuration, port publishing, restart behavior, networking, and deployment
lifecycle.

---

## Directory Structure

```text
compose/
├── docker-compose.yml
└── README.md
```

### `docker-compose.yml`

Defines the GitHub Readme Stats application service.

The Compose configuration is responsible for:

- Building the application container image.
- Selecting the project Dockerfile.
- Injecting runtime environment variables.
- Publishing the application port.
- Configuring container restart behavior.
- Creating the default application network.
- Starting and managing the application service.

Container-local health checking is defined by the Docker image and inherited by
the Compose service.

---

## Service Architecture

The current Compose configuration defines one application service:

```text
github-readme-stats
```

The runtime architecture is:

```text
Docker Compose
      │
      ▼
github-readme-stats service
      │
      ├── Build Docker image
      ├── Load runtime environment
      ├── Publish application port
      ├── Configure restart policy
      │
      ▼
github-readme-stats container
      │
      ▼
Node.js Express Server
```

The service and container use stable names so the deployment framework can
reliably inspect and manage the running application.

---

## Build Configuration

The Compose file is located at:

```text
compose/docker-compose.yml
```

The Docker build context is the project repository root:

```yaml
build:
  context: ..
  dockerfile: docker/Dockerfile
```

Because the Compose file is located inside the `compose/` directory, `..`
resolves to:

```text
github-readme-stats-deployment/
```

This allows the Docker build to access:

```text
docker/
deployment/github-readme-stats/
```

The root-level `.dockerignore` controls which files are included in the build
context.

---

## Application Source

The upstream GitHub Readme Stats repository is dynamically cloned into:

```text
deployment/github-readme-stats/
```

The Compose layer does not clone or update the repository.

Repository lifecycle operations are owned by the shell-script layer.

The expected lifecycle is:

```text
scripts/bootstrap.sh
        │
        ▼
scripts/clone.sh
        │
        ▼
deployment/github-readme-stats/
        │
        ▼
Docker Build
```

The application source must exist before the Compose build is executed.

---

## Environment Configuration

Runtime environment variables are loaded from:

```text
.env
```

The Compose configuration references the environment file using:

```yaml
env_file:
  - ../.env
```

The primary runtime variables are:

| Variable | Purpose |
| --- | --- |
| `PAT_1` | GitHub Personal Access Token |
| `PORT` | Application listening and published port |
| `CACHE_SECONDS` | Application cache duration |
| `ENVIRONMENT` | Deployment environment |
| `LOG_LEVEL` | Runtime or deployment logging level |

The Compose service also explicitly configures:

```text
NODE_ENV=production
```

The `.env` file contains runtime secrets and must never be committed to version
control.

The `.env.example` file documents required configuration keys without containing
real secret values.

---

## Port Mapping

The application port is configured dynamically:

```yaml
ports:
  - "${PORT:-9000}:${PORT:-9000}"
```

With the default configuration:

```text
PORT=9000
```

the runtime flow is:

```text
Host
:9000
   │
   ▼
Docker Port Mapping
   │
   ▼
Container
:9000
   │
   ▼
Express Server
:9000
```

If the `PORT` environment variable is changed, both the published host port and
the container application port change consistently.

The upstream Express application reads the same `PORT` environment variable.

---

## Container Naming

The application container uses the stable name:

```text
github-readme-stats
```

This allows the deployment framework and operators to inspect the container
using commands such as:

```bash
docker inspect github-readme-stats
```

and:

```bash
docker logs github-readme-stats
```

The deployment framework uses the same container name when verifying runtime
status and health.

---

## Restart Policy

The service uses:

```yaml
restart: unless-stopped
```

Docker automatically restarts the application container after unexpected
failures or Docker daemon restarts unless the container was explicitly stopped
by an operator.

This improves service resilience while still allowing intentional
administrative shutdowns.

---

## Networking

Docker Compose automatically creates a default project network for the
application.

For the current single-service architecture, no custom network configuration is
required.

The default network is sufficient because the application currently has no
additional containerized dependencies.

Future services such as databases, caches, or reverse proxies can be attached
to explicit networks if the deployment architecture expands.

---

## Health Checking

The Compose configuration does not duplicate the container health-check
definition.

The Docker image defines its health check using:

```text
docker/healthcheck.sh
```

The Compose service inherits that health check from the built image.

Docker reports the container as:

```text
starting
healthy
unhealthy
```

The deployment framework waits for the container to reach:

```text
healthy
```

before declaring the deployment successful.

This avoids maintaining duplicate health-check logic in both the Dockerfile and
Compose configuration.

---

## Validating the Compose Configuration

Run all commands in this section from the project root.

Validate the Compose configuration without printing resolved environment values:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    config \
    --quiet
```

A successful validation produces no output.

To list configured services:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    config \
    --services
```

Expected output:

```text
github-readme-stats
```

Avoid sharing the output of an unfiltered:

```text
docker compose config
```

command when real secrets are loaded because the resolved configuration may
contain environment variable values.

---

## Building the Application

To manually build the application image from the project root:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    build github-readme-stats
```

For normal deployments, use:

```bash
bash scripts/deploy.sh
```

The deployment script performs additional validation before and after the
Compose operations.

---

## Starting the Application

To manually start the application:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    up \
    --detach
```

Normal deployments should use:

```bash
bash scripts/deploy.sh
```

instead of invoking Compose directly.

---

## Stopping the Application

To stop and remove the Compose-managed application container and network:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    down
```

This does not delete the dynamically cloned upstream repository.

---

## Restarting the Application

To restart the application service:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    restart github-readme-stats
```

A restart reuses the currently deployed container configuration and image.

For a complete validated redeployment, use:

```bash
bash scripts/deploy.sh
```

---

## Viewing Container Status

To display the Compose service status:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    ps
```

To inspect Docker's container and health state directly:

```bash
docker inspect \
    --format '{{.State.Status}} / {{.State.Health.Status}}' \
    github-readme-stats
```

A successful deployment should report:

```text
running / healthy
```

---

## Viewing Container Logs

To display application logs:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    logs github-readme-stats
```

To follow logs continuously:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    logs \
    --follow \
    github-readme-stats
```

To display only recent logs:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    logs \
    --tail 50 \
    github-readme-stats
```

The deployment script automatically displays recent container logs when
container startup or application health verification fails.

---

## Deployment Integration

The Compose layer is orchestrated by:

```text
scripts/deploy.sh
```

The deployment lifecycle is:

```text
Verify Workspace
      │
      ▼
Validate Deployment Secrets
      │
      ▼
Verify Docker Runtime
      │
      ▼
Validate Compose Configuration
      │
      ▼
Build Application Image
      │
      ▼
Start Compose Service
      │
      ▼
Verify Container
      │
      ▼
Wait for Container Health
      │
      ▼
Verify Host HTTP Reachability
      │
      ▼
Deployment Complete
```

The deployment script invokes Compose using centralized paths and service names
defined in:

```text
scripts/config.sh
```

This prevents deployment-specific paths from being duplicated throughout the
automation scripts.

---

## Idempotent Deployment

The Compose architecture supports repeated deployments.

Running:

```bash
bash scripts/deploy.sh
```

when the application is already deployed will:

1. Validate the existing workspace.
2. Validate deployment configuration.
3. Rebuild or reuse cached image layers.
4. Reconcile the existing Compose service.
5. Verify that the container is running.
6. Wait for Docker health verification.
7. Verify application reachability.

This allows the same deployment workflow to be used for both initial and
subsequent deployments.

---

## Security Considerations

The Compose layer follows these security principles:

- Secrets are loaded from `.env` at runtime.
- Secrets are not embedded directly in the Compose file.
- `.env` is excluded from version control.
- The Docker image does not contain the `.env` file.
- Secret values are not intentionally printed by deployment scripts.
- The application container runs as a non-root user.
- Automated Compose validation uses quiet mode.

Operators should avoid printing or sharing fully resolved Compose configuration
when secrets are loaded.

---

## Ownership Boundaries

The Compose layer owns:

```text
Service orchestration
Container runtime configuration
Environment injection
Port publishing
Restart behavior
Container networking
```

The Compose layer does not own:

```text
Docker image implementation
Repository cloning
Repository updates
Workspace configuration
Deployment verification
Backup creation
Backup restoration
```

These responsibilities belong to the Docker and shell-script layers.

---

## Related Components

```text
deployment/github-readme-stats/
        │
        │ Application source
        ▼
docker/Dockerfile
        │
        │ Image construction
        ▼
Docker Image
        │
        ▼
compose/docker-compose.yml
        │
        │ Runtime orchestration
        ▼
github-readme-stats Container
        │
        ▼
scripts/deploy.sh
        │
        │ Deployment verification
        ▼
Running Application
```

---

## Recommended Usage

For normal project operation, use the deployment framework rather than invoking
Compose commands directly:

```bash
bash scripts/bootstrap.sh
bash scripts/deploy.sh
```

Direct Compose commands are primarily intended for debugging, inspection, and
manual administrative operations.