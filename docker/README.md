# Docker Runtime

This directory contains the Docker runtime configuration for the GitHub Readme Stats application.

The Docker layer packages the upstream GitHub Readme Stats application into a reproducible container image suitable for deployment through the project's Docker Compose and Nginx reverse proxy architecture.

---

## Purpose

The Docker runtime is responsible for:

- Building the GitHub Readme Stats application image.
- Installing Node.js dependencies.
- Packaging the application source code.
- Running the application as a non-root user.
- Providing container startup validation.
- Providing application health checking.
- Exposing the internal application port.
- Supporting reproducible container deployment.

The Docker layer does not publish the application directly to external clients.

Public HTTP traffic is handled by the Nginx reverse proxy.

---

## Directory Structure

```text
docker/
├── README.md
├── Dockerfile
├── entrypoint.sh
└── healthcheck.sh
```

The Docker build context also uses the project-level:

```text
.dockerignore
```

---

## Runtime Architecture

The application container operates behind Nginx.

```text
Client
  │
  ▼
Nginx :80
  │
  │ Internal Docker Network
  ▼
GitHub Readme Stats :9000
```

The application container does not publish port `9000` directly to the host.

---

## Dockerfile

The application image is defined in:

```text
docker/Dockerfile
```

The Dockerfile uses a multi-stage build architecture.

The primary stages are:

```text
dependencies
    │
    └── Install Node.js dependencies
            │
            ▼
runtime
    │
    └── Build the final application runtime image
```

This separates dependency installation from runtime image construction.

---

## Base Image

The runtime uses:

```text
node:22-alpine
```

The Node.js version satisfies the upstream application's engine requirement:

```text
Node.js >= 22
```

The Alpine-based image provides a relatively small runtime foundation.

---

## Dependency Installation

Dependencies are installed using:

```text
npm ci
```

The build copies:

```text
package.json
package-lock.json
```

before running dependency installation.

Using `npm ci` provides deterministic installation based on the lock file.

---

## Upstream Application Source

The GitHub Readme Stats source repository is cloned into:

```text
deployment/github-readme-stats
```

during the project bootstrap and clone workflow.

The Docker build copies the runtime application source from this directory into:

```text
/app
```

inside the container.

The cloned upstream repository is a runtime workspace artifact and is not committed to the deployment repository.

---

## Runtime Working Directory

The application runs from:

```text
/app
```

inside the container.

---

## Non-Root Runtime

The application runs using the Node.js image's non-root:

```text
node
```

user.

Application files and installed dependencies are owned appropriately for the runtime user.

Running the application as a non-root user reduces the privileges available to the application process inside the container.

---

## Entrypoint

Container startup is managed by:

```text
docker/entrypoint.sh
```

The entrypoint performs startup validation before launching the application.

The entrypoint is installed inside the image at:

```text
/usr/local/bin/entrypoint.sh
```

and marked executable during the image build.

---

## Health Check

Application health checking is provided by:

```text
docker/healthcheck.sh
```

The health check script is installed inside the image at:

```text
/usr/local/bin/healthcheck.sh
```

The script verifies that the application is responding inside the container.

The container health state can be inspected using:

```powershell
docker inspect --format='{{.State.Health.Status}}' github-readme-stats
```

Expected healthy state:

```text
healthy
```

---

## Internal Application Port

The GitHub Readme Stats application listens on:

```text
9000
```

The port is configured through:

```text
PORT
```

Default:

```dotenv
PORT=9000
```

This port is an internal application port.

It is not the public deployment port.

---

## Network Exposure

The application container does not publish port `9000` directly to the host.

Docker Compose declares the application port for internal service communication:

```yaml
expose:
  - "9000"
```

The runtime communication model is:

```text
github-readme-stats-nginx
        │
        │ app-network
        ▼
github-readme-stats:9000
```

External clients access the application through Nginx.

---

## Public HTTP Access

The public HTTP port is controlled separately through:

```text
HTTP_PORT
```

The default architecture is:

```text
Host :80
   │
   ▼
Nginx :80
   │
   ▼
Application :9000
```

The application container should never require direct host access under the current architecture.

---

## Runtime Environment Variables

The application receives runtime configuration including:

```text
PAT_1
PORT
CACHE_SECONDS
ENVIRONMENT
LOG_LEVEL
NODE_ENV
```

Secrets are provided at runtime and are not baked into the Docker image.

The GitHub Personal Access Token must never be committed to:

- The Dockerfile.
- Docker image layers.
- Git-tracked environment files.
- Documentation examples containing real credentials.

---

## Build Context

The Docker build context is the project root.

This allows the Dockerfile to access:

```text
deployment/github-readme-stats
docker/entrypoint.sh
docker/healthcheck.sh
```

The build is configured through Docker Compose.

---

## `.dockerignore`

The project-level `.dockerignore` controls which files are excluded from the Docker build context.

Typical exclusions include:

- Git metadata.
- Local environment files.
- Logs.
- Backups.
- Temporary files.
- IDE metadata.
- Unnecessary build artifacts.

The `.dockerignore` should prevent sensitive or unnecessary files from being sent to the Docker daemon during image builds.

---

## Build the Application Image

Run from the project root:

```text
D:\Vishal72021\github-readme-stats-deployment
```

Build through Docker Compose:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml build github-readme-stats
```

The normal deployment workflow performs this build automatically.

---

## Start the Application Stack

The recommended deployment command is:

```powershell
bash scripts/deploy.sh
```

This deploys both:

```text
github-readme-stats
github-readme-stats-nginx
```

and verifies their health.

For manual Compose operation:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

---

## Inspect the Application Container

Run:

```powershell
docker inspect github-readme-stats
```

Check container health directly:

```powershell
docker inspect --format='{{.State.Health.Status}}' github-readme-stats
```

Expected:

```text
healthy
```

---

## View Application Logs

Run:

```powershell
docker logs github-readme-stats
```

Or through Compose:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml logs github-readme-stats
```

Follow logs:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml logs -f github-readme-stats
```

---

## Verify Port Isolation

Run:

```powershell
docker port github-readme-stats
```

There should be no host-published mapping for port `9000`.

Attempting direct access from the host:

```powershell
curl.exe --max-time 5 http://localhost:9000
```

should fail.

This is expected behavior.

The application must be accessed through Nginx.

---

## Verify Application Through Nginx

Run:

```powershell
curl.exe -o NUL -s -w "%{http_code}`n" "http://localhost/api?username=octocat"
```

Expected:

```text
200
```

This verifies that the containerized application is reachable through the supported reverse proxy path.

---

## Restart the Application Container

Run:

```powershell
docker restart github-readme-stats
```

Check health:

```powershell
docker inspect --format='{{.State.Health.Status}}' github-readme-stats
```

After the container becomes healthy, verify the application through Nginx:

```powershell
curl.exe -o NUL -s -w "%{http_code}`n" "http://localhost/api?username=octocat"
```

Expected:

```text
200
```

---

## Image Security Considerations

The runtime image follows several baseline container security practices:

- Uses a minimal Alpine-based Node.js image.
- Runs the application as a non-root user.
- Keeps secrets outside the image.
- Uses deterministic dependency installation.
- Separates dependency installation from runtime construction.
- Uses explicit application health checks.
- Avoids direct public exposure of the application port.

Dependency vulnerabilities reported by `npm audit` originate from the dependency tree used by the upstream application and should be reviewed separately.

Automated commands such as:

```text
npm audit fix --force
```

should not be applied blindly because they may introduce breaking dependency changes.

---

## Runtime Boundary

The Docker runtime owns the application container.

The Compose layer owns service orchestration.

The Nginx layer owns external HTTP ingress.

The responsibility boundaries are:

```text
Docker
   │
   └── Application runtime image

Docker Compose
   │
   └── Runtime service orchestration

Nginx
   │
   └── Public HTTP entry point

Deployment Scripts
   │
   └── Automated deployment and verification
```

Keeping these responsibilities separate reduces coupling between infrastructure components.

---

## Current Limitations

The current Docker runtime does not provide:

- TLS termination.
- HTTPS configuration.
- Container image registry publishing.
- Multi-architecture image publishing.
- Kubernetes deployment.
- Automated vulnerability remediation.

These concerns belong to future deployment milestones.

---

## Future Extensions

The Docker architecture can later support:

- Image registry publishing.
- Versioned application images.
- Image vulnerability scanning.
- Software Bill of Materials generation.
- Image signing.
- Multi-platform builds.
- CI/CD image pipelines.
- Kubernetes deployment.

Changes to the Docker runtime should preserve the existing separation between the internal application container and the public reverse proxy boundary.