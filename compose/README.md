# Docker Compose

This directory contains the Docker Compose configuration used to orchestrate the GitHub Readme Stats Deployment runtime stack.

Docker Compose manages the application container, Nginx reverse proxy, container networking, environment configuration, health checks, restart policies, and service dependencies.

---

## Purpose

The Compose layer defines how the deployment services operate together.

Its responsibilities include:

- Building the GitHub Readme Stats application image.
- Running the application container.
- Running the Nginx reverse proxy.
- Injecting runtime environment variables.
- Creating the internal Docker network.
- Managing container health checks.
- Managing service startup dependencies.
- Publishing the public HTTP port.
- Mounting Nginx configuration.
- Applying container restart policies.

---

## Directory Structure

```text
compose/
├── README.md
└── docker-compose.yml
```

The runtime definition is contained in:

```text
compose/docker-compose.yml
```

---

## Runtime Architecture

The deployment uses two runtime services:

```text
Client
  │
  │ HTTP
  ▼
Host : HTTP_PORT
  │
  ▼
Nginx :80
  │
  │ app-network
  ▼
github-readme-stats :9000
```

The services are:

```text
github-readme-stats
    └── Application service

nginx
    └── Reverse proxy service
```

Nginx is the only service that publishes a host-facing HTTP port.

---

## Application Service

The application service is:

```text
github-readme-stats
```

Its container name is:

```text
github-readme-stats
```

The application image is built from the project Dockerfile.

Build context:

```text
Project Root
```

Dockerfile:

```text
docker/Dockerfile
```

The application runs internally on:

```text
9000
```

---

## Application Environment

The application receives runtime configuration through environment variables.

Configured variables include:

```text
PAT_1
PORT
CACHE_SECONDS
ENVIRONMENT
LOG_LEVEL
NODE_ENV
```

Sensitive values are loaded from the local `.env` file.

The `.env` file must not be committed to Git.

---

## Application Port Exposure

The application declares:

```yaml
expose:
  - "9000"
```

Port `9000` is available for communication between containers on the Docker network.

It is not published directly to the host.

The following architecture is intentionally prevented:

```text
Host
  │
  ▼
Application :9000
```

Instead, application traffic must pass through Nginx.

---

## Nginx Service

The reverse proxy service is:

```text
nginx
```

Its container name is:

```text
github-readme-stats-nginx
```

The service uses the official:

```text
nginx:alpine
```

container image.

Nginx acts as the public HTTP entry point for the deployment stack.

---

## Public HTTP Port

The Nginx service publishes:

```text
HTTP_PORT → 80
```

The Compose configuration uses:

```yaml
ports:
  - "${HTTP_PORT:-80}:80"
```

The default host-facing port is:

```text
80
```

Configured through:

```dotenv
HTTP_PORT=80
```

The resulting default endpoint is:

```text
http://localhost
```

For a custom port:

```text
http://localhost:<HTTP_PORT>
```

---

## Internal Network

Both services are attached to:

```text
app-network
```

The network uses the Docker bridge driver.

The communication model is:

```text
github-readme-stats-nginx
        │
        │ app-network
        ▼
github-readme-stats:9000
```

Docker's internal DNS resolves service names automatically.

Nginx therefore reaches the application through:

```text
github-readme-stats:9000
```

No static container IP addresses are required.

---

## Service Dependency

The Nginx service depends on the application service.

Nginx waits for the application to reach a healthy state before startup.

The dependency contract is:

```text
github-readme-stats
        │
        │ healthy
        ▼
nginx
```

This reduces the likelihood of Nginx starting before the application is ready.

---

## Application Health Check

The application container provides its own health check.

The health check verifies that the GitHub Readme Stats application is operational inside the container.

Container health can be inspected with:

```powershell
docker inspect --format='{{.State.Health.Status}}' github-readme-stats
```

Expected:

```text
healthy
```

---

## Nginx Health Check

The Nginx service provides an independent health check using:

```text
/nginx-health
```

The health check verifies the Nginx process without depending on the upstream application.

Container health can be inspected with:

```powershell
docker inspect --format='{{.State.Health.Status}}' github-readme-stats-nginx
```

Expected:

```text
healthy
```

---

## Nginx Configuration Mounts

The Compose stack mounts repository-managed Nginx configuration into the Nginx container.

Global configuration:

```text
../nginx/nginx.conf
        │
        ▼
/etc/nginx/nginx.conf
```

Application configuration:

```text
../nginx/conf.d
        │
        ▼
/etc/nginx/conf.d
```

Both mounts are read-only.

---

## Restart Policy

Both runtime services use:

```text
unless-stopped
```

This allows containers to restart automatically after unexpected failures while respecting explicit administrative stops.

---

## Environment File

The Compose stack loads runtime configuration from:

```text
.env
```

The example configuration contract is stored in:

```text
.env.example
```

The real `.env` file contains deployment-specific values and secrets and must remain outside version control.

---

## Validate Compose Configuration

Run from the project root:

```text
D:\Vishal72021\github-readme-stats-deployment
```

Validate the complete Compose configuration:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml config --quiet
```

No output indicates successful validation.

---

## List Services

Run:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml config --services
```

Expected:

```text
github-readme-stats
nginx
```

---

## List Networks

Run:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml config --networks
```

Expected:

```text
app-network
```

---

## Build the Application

Run from the project root:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml build github-readme-stats
```

Nginx uses the prebuilt official `nginx:alpine` image and does not require a project-specific image build.

---

## Start the Stack

Run:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml up -d
```

This starts:

```text
github-readme-stats
github-readme-stats-nginx
```

---

## View Stack Status

Run:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml ps
```

Expected state:

```text
github-readme-stats
    Running
    Healthy
    9000/tcp

github-readme-stats-nginx
    Running
    Healthy
    HTTP_PORT → 80/tcp
```

Port `9000` must not be published to the host.

---

## View Logs

Application logs:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml logs github-readme-stats
```

Nginx logs:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml logs nginx
```

Follow logs:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml logs -f
```

---

## Verify Nginx Health

With the default port:

```powershell
curl.exe http://localhost/nginx-health
```

Expected:

```text
healthy
```

---

## Verify Application Routing

Run:

```powershell
curl.exe -o NUL -s -w "%{http_code}`n" "http://localhost/api?username=octocat"
```

Expected:

```text
200
```

The request path is:

```text
Host
  │
  ▼
Nginx
  │
  ▼
app-network
  │
  ▼
github-readme-stats:9000
```

---

## Verify Port Isolation

Run:

```powershell
docker port github-readme-stats
```

The application should not have a host-published port.

Direct host access should fail:

```powershell
curl.exe --max-time 5 http://localhost:9000
```

---

## Stop the Stack

Run:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml down
```

This removes the running containers and Compose-managed network.

Application data and source files remain unaffected.

---

## Recreate the Stack

Run:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml up -d --build
```

This rebuilds the application image and recreates the runtime stack when required.

---

## Deployment Automation

Normal deployments should use:

```powershell
bash scripts/deploy.sh
```

The deployment script manages:

```text
Workspace verification
        ↓
Secret validation
        ↓
Docker runtime verification
        ↓
Compose validation
        ↓
Application image build
        ↓
Stack deployment
        ↓
Application container verification
        ↓
Application health verification
        ↓
Nginx container verification
        ↓
Nginx health verification
        ↓
End-to-end reverse proxy verification
```

Direct Compose commands are primarily intended for development, debugging, and operational inspection.

---

## Production Boundary

The Compose architecture establishes the following service boundary:

```text
External
   │
   ▼
Nginx
   │
   ▼
Internal Docker Network
   │
   ▼
Application
```

The application container must remain internally accessible only.

Future external traffic controls should be implemented through the reverse proxy layer.

---

## Future Extensions

The Compose architecture can be extended to support:

- TLS certificate services.
- HTTPS termination.
- Monitoring services.
- Metrics exporters.
- Centralized logging.
- Additional application services.
- Persistent infrastructure services.
- Production orchestration platforms.

Any major change to service topology should be treated as an explicit architecture change.