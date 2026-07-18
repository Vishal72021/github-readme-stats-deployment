# Nginx Reverse Proxy

This directory contains the Nginx reverse proxy configuration for the GitHub Readme Stats Deployment project.

Nginx acts as the public HTTP entry point for the deployment stack. Incoming client requests are accepted by Nginx and forwarded to the GitHub Readme Stats application over an internal Docker network.

The application container is intentionally not exposed directly to the host.

---

## Purpose

The Nginx layer provides a dedicated reverse proxy boundary between external clients and the GitHub Readme Stats application.

Its responsibilities include:

- Accepting incoming HTTP traffic.
- Acting as the single public HTTP entry point.
- Forwarding application requests to the internal application service.
- Preserving client and proxy request metadata.
- Providing an independent reverse proxy health endpoint.
- Managing upstream connection behavior.
- Applying proxy connection and response timeouts.
- Providing a foundation for future HTTPS and TLS termination.

Nginx does not manage application runtime behavior or application secrets.

---

## Architecture

The deployment uses a two-service runtime architecture:

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
  │
  ▼
GitHub API
```

Only Nginx publishes a host-facing HTTP port.

The GitHub Readme Stats application remains accessible only through the internal Docker network.

---

## Directory Structure

```text
nginx/
├── README.md
├── nginx.conf
└── conf.d/
    └── github-readme-stats.conf
```

### `nginx.conf`

Contains global Nginx runtime configuration.

Responsibilities include:

- Worker process configuration.
- Connection handling.
- MIME type configuration.
- Access logging.
- Error logging.
- HTTP runtime defaults.
- Gzip compression.
- Baseline security behavior.
- Loading application-specific configuration files.

Application-specific routing is intentionally excluded from this file.

---

### `conf.d/github-readme-stats.conf`

Contains the reverse proxy configuration for the GitHub Readme Stats application.

Responsibilities include:

- Defining the application upstream.
- Accepting incoming HTTP requests.
- Providing the Nginx health endpoint.
- Forwarding application traffic.
- Preserving request metadata.
- Configuring proxy timeouts.
- Managing upstream keepalive connections.

---

## Global Nginx Configuration

The global configuration is defined in:

```text
nginx/nginx.conf
```

The configuration uses automatic worker process detection:

```nginx
worker_processes auto;
```

This allows Nginx to determine an appropriate number of worker processes based on available CPU resources.

---

## Container Logging

Nginx logs are written directly to standard container output streams.

Access logs:

```text
/dev/stdout
```

Error logs:

```text
/dev/stderr
```

This allows logs to be accessed through Docker:

```powershell
docker logs github-readme-stats-nginx
```

or through Docker Compose:

```powershell
docker compose --env-file .env -f compose/docker-compose.yml logs nginx
```

---

## Security Configuration

Nginx disables server version tokens:

```nginx
server_tokens off;
```

This prevents the exact Nginx version from being exposed through standard response headers and generated error pages.

The current configuration intentionally provides only baseline HTTP reverse proxy security.

Advanced security controls such as TLS, rate limiting, and additional security headers are outside the scope of the current reverse proxy milestone.

---

## Request Body Limit

The global configuration limits request bodies to:

```text
1 MB
```

The GitHub Readme Stats application primarily processes HTTP GET requests and query parameters and does not require large request bodies.

This limit can be changed if future application requirements introduce larger request payloads.

---

## Compression

Gzip compression is enabled for supported response types.

Configured types include:

- JavaScript.
- JSON.
- XML.
- SVG.
- CSS.
- Plain text.

This is particularly relevant because GitHub Readme Stats returns SVG content.

---

## Application Upstream

The application-specific configuration defines the following upstream:

```nginx
upstream github_readme_stats {
    server github-readme-stats:9000;
    keepalive 32;
}
```

The upstream hostname:

```text
github-readme-stats
```

corresponds to the Docker Compose application service.

Docker's internal DNS resolves the service hostname automatically.

No static container IP addresses are used.

---

## Docker Network

Both runtime services are connected to:

```text
app-network
```

The communication path is:

```text
github-readme-stats-nginx
        │
        │ app-network
        ▼
github-readme-stats:9000
```

The application does not need a host-published port for Nginx to communicate with it.

---

## Request Routing

Nginx listens internally on:

```text
80
```

All application requests received at `/` are forwarded to the application upstream.

Example request:

```text
GET /api?username=octocat
```

Request flow:

```text
Client
  │
  ▼
Nginx
  │
  ▼
github_readme_stats upstream
  │
  ▼
github-readme-stats:9000
  │
  ▼
GitHub Readme Stats
```

The original request URI is preserved when forwarding the request.

---

## Forwarded Headers

Nginx forwards request metadata using the following headers:

```text
Host
X-Real-IP
X-Forwarded-For
X-Forwarded-Proto
```

These headers preserve information about:

- The original host.
- The connecting client address.
- The proxy forwarding chain.
- The original request protocol.

---

## Proxy Protocol

Upstream communication uses:

```text
HTTP/1.1
```

Persistent upstream connections are supported through the configured upstream keepalive pool.

The proxy removes the default `Connection` header before forwarding requests to support upstream connection reuse.

---

## Proxy Timeouts

The reverse proxy defines explicit timeout behavior.

Connection timeout:

```text
10 seconds
```

Send timeout:

```text
60 seconds
```

Read timeout:

```text
60 seconds
```

These values prevent upstream operations from waiting indefinitely while still allowing sufficient time for application responses.

---

## Nginx Health Endpoint

Nginx exposes an independent health endpoint:

```text
/nginx-health
```

Successful response:

```text
HTTP 200
healthy
```

The endpoint is handled directly by Nginx.

It does not contact the GitHub Readme Stats application.

This allows reverse proxy health to be evaluated independently from application health.

---

## Health Architecture

The deployment maintains three separate verification layers:

```text
Application Health
      │
      └── Verifies the GitHub Readme Stats container

Reverse Proxy Health
      │
      └── Verifies the Nginx container

End-to-End Verification
      │
      └── Verifies Host → Nginx → Application
```

This separation makes deployment failures easier to diagnose.

---

## Port Model

The application listens internally on:

```text
9000
```

The application port is not published directly to the host.

Nginx listens internally on:

```text
80
```

The host-facing HTTP port is controlled through:

```text
HTTP_PORT
```

Default:

```dotenv
HTTP_PORT=80
```

The resulting port flow is:

```text
Host : HTTP_PORT
        │
        ▼
Nginx :80
        │
        ▼
Application :9000
```

With the default configuration:

```text
Host :80
   │
   ▼
Nginx :80
   │
   ▼
github-readme-stats :9000
```

---

## Configuration Mounts

Docker Compose mounts the Nginx configuration into the container.

Global configuration:

```text
nginx/nginx.conf
        │
        ▼
/etc/nginx/nginx.conf
```

Application configuration:

```text
nginx/conf.d/
        │
        ▼
/etc/nginx/conf.d/
```

Both mounts are read-only.

This prevents the running Nginx container from modifying repository-managed configuration.

---

## Validate Nginx Configuration

Run from the project root:

```text
D:\Vishal72021\github-readme-stats-deployment
```

Validate the running container configuration:

```powershell
docker exec github-readme-stats-nginx nginx -t
```

Expected output:

```text
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
```

---

## Verify Nginx Health

With the default HTTP port:

```powershell
curl.exe http://localhost/nginx-health
```

Expected response:

```text
healthy
```

For a custom HTTP port:

```powershell
curl.exe http://localhost:<HTTP_PORT>/nginx-health
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

This verifies the complete request path:

```text
Host
  │
  ▼
Nginx
  │
  ▼
Docker Network
  │
  ▼
GitHub Readme Stats
```

---

## Verify Application Port Isolation

Run:

```powershell
docker port github-readme-stats
```

The application container should not report a host mapping for port `9000`.

Direct access should fail:

```powershell
curl.exe --max-time 5 http://localhost:9000
```

Application traffic must enter through Nginx.

---

## Restart Verification

Restart the Nginx container:

```powershell
docker restart github-readme-stats-nginx
```

Check health:

```powershell
docker inspect --format='{{.State.Health.Status}}' github-readme-stats-nginx
```

After the container becomes healthy, verify:

```powershell
curl.exe http://localhost/nginx-health
```

and:

```powershell
curl.exe -o NUL -s -w "%{http_code}`n" "http://localhost/api?username=octocat"
```

---

## Security Boundary

Nginx establishes the HTTP boundary for the deployment.

The supported architecture is:

```text
External Client
      │
      ▼
Nginx Reverse Proxy
      │
      ▼
Internal Docker Network
      │
      ▼
GitHub Readme Stats
```

The application container must not expose port `9000` directly to external clients.

This ensures that future infrastructure controls can be implemented centrally at the reverse proxy layer.

---

## Current Limitations

The current reverse proxy configuration provides HTTP only.

It does not currently implement:

- HTTPS.
- TLS certificate management.
- HTTP-to-HTTPS redirects.
- Rate limiting.
- Request throttling.
- Advanced security headers.
- Authentication.
- Web Application Firewall functionality.

These capabilities should be introduced through separate architecture changes.

---

## Future Extensions

The reverse proxy architecture is designed to support future capabilities including:

- HTTPS termination.
- Automated TLS certificate management.
- HTTP-to-HTTPS redirects.
- Security headers.
- Rate limiting.
- Request throttling.
- Access control.
- Multiple application upstreams.
- Load balancing.
- Observability and metrics integration.

The current HTTP reverse proxy configuration should remain stable unless a future architecture decision explicitly changes its contract.