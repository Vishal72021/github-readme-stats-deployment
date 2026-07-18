# Docker Image

This directory contains the container image definition and runtime scripts used
to run GitHub Readme Stats as a standalone Docker container.

The Docker layer is responsible for converting the upstream GitHub Readme Stats
application into a reproducible container image that can be deployed by the
project's Compose and deployment layers.

---

## Directory Structure

```text
docker/
├── Dockerfile
├── entrypoint.sh
├── healthcheck.sh
└── README.md
```

### `Dockerfile`

Defines the production container image for GitHub Readme Stats.

The image:

- Uses Node.js 22 on Alpine Linux.
- Installs application dependencies in a dedicated dependency stage.
- Copies the cloned upstream application into the runtime image.
- Installs `curl` for container-local health checks.
- Runs the application as the non-root `node` user.
- Configures the container entrypoint.
- Configures the Docker health check.
- Starts the standalone Express server.

### `entrypoint.sh`

Initializes the application container before starting the Node.js process.

The entrypoint:

- Validates required runtime configuration.
- Ensures the GitHub Personal Access Token is configured.
- Ensures the application port is configured.
- Prints safe runtime information.
- Never prints secret values.
- Uses `exec` to hand control to the application process.

Using `exec` ensures that the Node.js process becomes the primary container
process and receives operating-system signals correctly.

### `healthcheck.sh`

Performs an HTTP reachability check from inside the running container.

The health check verifies that the standalone Express server is accepting HTTP
connections on the configured application port.

The script returns:

```text
0    Application is reachable
1    Application is unreachable
```

Docker uses this result to determine whether the container is healthy or
unhealthy.

---

## Build Context

The Docker image uses the project repository root as its build context:

```text
github-readme-stats-deployment/
```

This is required because the image build needs access to both:

```text
deployment/github-readme-stats/
docker/
```

The application source is dynamically cloned into:

```text
deployment/github-readme-stats/
```

by the deployment framework.

The deployment repository therefore does not vendor or permanently maintain a
copy of the upstream GitHub Readme Stats source code.

---

## Docker Ignore Configuration

The Docker build context is controlled by the root-level:

```text
.dockerignore
```

The ignore file prevents unnecessary or sensitive files from being sent to the
Docker build context.

Examples include:

- `.git`
- `.env`
- IDE configuration
- logs
- backups
- caches
- temporary files
- existing Node.js dependencies
- build artifacts

The runtime application source under:

```text
deployment/github-readme-stats/
```

must remain available to the Docker build context.

The `docker/` directory must also remain available because the Dockerfile copies
the container runtime scripts from this directory.

---

## Image Architecture

The Dockerfile uses a multi-stage build.

```text
Dependency Stage
      │
      ├── Copy package.json
      ├── Copy package-lock.json
      └── npm ci
              │
              ▼
         node_modules
              │
              ▼
Runtime Stage
      │
      ├── Node.js 22 Alpine
      ├── curl
      ├── Application dependencies
      ├── Application source
      ├── entrypoint.sh
      └── healthcheck.sh
```

This separates dependency installation from final runtime image construction.

---

## Dependency Installation

The upstream standalone Express server imports the `express` package at runtime.

The upstream project currently declares `express` as a development dependency.
For this reason, the dependency stage uses:

```text
npm ci
```

rather than:

```text
npm ci --omit=dev
```

This ensures all dependencies required by the standalone Express deployment are
available in the final container.

Dependencies are installed using the upstream lock file to provide deterministic
dependency resolution.

---

## Runtime User

The application runs as the built-in non-root Node.js user:

```text
node
```

Application source and dependency files are copied into the runtime image with
the appropriate ownership.

This avoids running the GitHub Readme Stats application as the root user.

---

## Application Startup

The container startup flow is:

```text
Container Start
      │
      ▼
entrypoint.sh
      │
      ├── Validate PAT_1
      ├── Validate PORT
      ├── Print safe runtime information
      │
      ▼
exec node express.js
      │
      ▼
GitHub Readme Stats
```

The standalone Express application listens on:

```text
0.0.0.0:${PORT}
```

The default application port is:

```text
9000
```

The port can be overridden through runtime environment configuration.

---

## Container Health Check

The Docker image defines a native container health check.

The health-check script performs an HTTP request against the application from
inside the running container.

The default health configuration is:

```text
Host: 127.0.0.1
Port: ${PORT:-9000}
Path: /api/
```

The `/api/` route is used as an HTTP reachability probe for the standalone
Express server.

The health check verifies server reachability rather than the success of a
specific GitHub API operation.

Docker reports the container health state as one of:

```text
starting
healthy
unhealthy
```

The deployment script waits for the container to become healthy before declaring
the deployment successful.

---

## Runtime Configuration

Runtime configuration is provided through environment variables.

| Variable | Purpose |
| --- | --- |
| `PAT_1` | GitHub Personal Access Token used by GitHub Readme Stats |
| `PORT` | Application listening port |
| `CACHE_SECONDS` | Application cache duration |
| `ENVIRONMENT` | Deployment environment |
| `LOG_LEVEL` | Runtime or deployment logging level |

Secrets must never be stored directly in the Dockerfile or committed to the
repository.

Runtime values are injected into the container through Docker Compose.

---

## Building the Image

Image builds are normally managed by:

```text
scripts/deploy.sh
```

For manual validation, run the following command from the project root:

```bash
docker compose \
    --env-file .env \
    --file compose/docker-compose.yml \
    build github-readme-stats
```

The deployment framework should be preferred for normal deployments because it
also performs prerequisite validation, configuration validation, container
verification, and application health checks.

---

## Inspecting Container Health

From the project root, container status and health can be inspected with:

```bash
docker inspect \
    --format '{{.State.Status}} / {{.State.Health.Status}}' \
    github-readme-stats
```

A healthy deployment should report:

```text
running / healthy
```

---

## Security Considerations

The Docker implementation follows these security principles:

- Secrets are injected at runtime rather than embedded in the image.
- Secret values are never printed by the container entrypoint.
- The application runs as a non-root user.
- The `.env` file is excluded from the Docker build context.
- Container health checks do not expose credentials.
- Application dependencies are installed from the upstream lock file.
- Runtime configuration is separated from image construction.

Never commit the project `.env` file or include Personal Access Token values in
documentation, logs, screenshots, or shared command output.

---

## Ownership Boundaries

The Docker layer owns:

```text
Image construction
Container initialization
Container-local health checking
Runtime user configuration
Application process startup
```

The Docker layer does not own:

```text
Repository cloning
Workspace configuration
Deployment orchestration
Application updates
Backups
Restoration
```

Those responsibilities belong to other layers of the deployment framework.

---

## Related Components

```text
scripts/bootstrap.sh
        │
        ▼
deployment/github-readme-stats/
        │
        ▼
docker/Dockerfile
        │
        ▼
Container Image
        │
        ▼
compose/docker-compose.yml
        │
        ▼
scripts/deploy.sh
        │
        ▼
Running Application
```