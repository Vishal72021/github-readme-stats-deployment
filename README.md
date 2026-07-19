# GitHub Readme Stats Deployment

Production-ready, self-hosted deployment infrastructure for GitHub
Readme Stats using Docker, Docker Compose, Nginx, HTTPS, Let's Encrypt,
and automated operational tooling.

This repository manages the infrastructure and deployment lifecycle
around the upstream GitHub Readme Stats application. It is designed to
provide a reproducible, secure, maintainable, and production-oriented
self-hosted deployment.

## Overview

The project separates deployment infrastructure from the upstream
application source.

The upstream GitHub Readme Stats repository is cloned at deployment time
into a Git-ignored deployment workspace. Docker builds the application,
Docker Compose orchestrates the runtime services, and Nginx provides the
public reverse proxy and TLS termination layer.

The deployment includes:

-   Automated environment validation
-   Workspace bootstrap and upstream repository cloning
-   Docker image builds
-   Docker Compose orchestration
-   Nginx reverse proxying
-   HTTPS and TLS termination
-   HTTP-to-HTTPS redirection
-   Let's Encrypt certificate management
-   Automated Certbot renewal hooks
-   Application and proxy health checks
-   End-to-end HTTPS deployment verification
-   Backup and update automation
-   Persistent host firewall configuration
-   Automatic recovery after VM reboot

## Live Deployment

Production domain:

`vishal-github-stats.duckdns.org`

Example GitHub stats endpoint:

`https://vishal-github-stats.duckdns.org/api?username=Vishal72021`

All public HTTP traffic is redirected to HTTPS.

## Architecture

The production request path is:

``` text
Internet
    |
    | TCP 80 / 443
    v
Oracle Cloud Compute Instance
    |
    v
Nginx Reverse Proxy
    |
    | HTTP 80 -> HTTPS redirect
    | HTTPS 443 -> TLS termination
    v
Docker Network
    |
    v
GitHub Readme Stats
    |
    | Internal TCP 9000
    v
GitHub API
```

The application container is not exposed directly to the public
Internet. Public traffic reaches the application through Nginx.

### Service Responsibilities

  Component              Responsibility
  ---------------------- -----------------------------------
  Oracle Cloud Compute   Production VM hosting
  Docker                 Application container runtime
  Docker Compose         Multi-container orchestration
  Nginx                  Reverse proxy and TLS termination
  Let's Encrypt          TLS certificate authority
  Certbot                Certificate issuance and renewal
  DuckDNS                Production domain resolution
  iptables               Host-level firewall
  netfilter-persistent   Firewall persistence

## Features

### Deployment Automation

-   Environment validation
-   Deployment workspace configuration
-   Automated upstream repository cloning
-   Docker image build automation
-   Docker Compose deployment
-   Container health verification
-   Reverse proxy verification
-   Public HTTPS endpoint verification

### Production Networking

-   Nginx reverse proxy
-   HTTP-to-HTTPS redirection
-   TLS termination
-   Public ports 80 and 443
-   Internal-only application port 9000
-   Host firewall protection
-   Persistent firewall rules

### TLS and Certificate Management

-   Let's Encrypt TLS certificates
-   Certbot standalone HTTP-01 validation
-   Automated pre-renewal Nginx shutdown
-   Automated post-renewal Nginx startup
-   Repository-managed renewal hooks
-   Certbot renewal dry-run validation

### Reliability

-   Docker health checks
-   Nginx health checks
-   End-to-end deployment validation
-   `unless-stopped` container restart policies
-   Docker automatic startup
-   Persistent firewall configuration
-   VM reboot recovery

### Operations

-   Deployment scripts
-   Update automation
-   Backup automation
-   Validation tooling
-   Production operations documentation

## Technology Stack

  Layer                    Technology
  ------------------------ -----------------------------
  Application              GitHub Readme Stats
  Runtime                  Node.js
  Containers               Docker
  Orchestration            Docker Compose
  Reverse Proxy            Nginx
  TLS                      Let's Encrypt
  Certificate Automation   Certbot
  Cloud                    Oracle Cloud Infrastructure
  Operating System         Ubuntu 24.04 LTS
  DNS                      DuckDNS
  Firewall                 iptables
  Firewall Persistence     netfilter-persistent
  Automation               Bash

## Repository Structure

``` text
github-readme-stats-deployment/
|
|-- .github/
|-- compose/
|   `-- docker-compose.yml
|
|-- deployment/
|   `-- github-readme-stats/        # Runtime clone; Git-ignored
|
|-- docker/
|   |-- entrypoint.sh
|   `-- healthcheck.sh
|
|-- docs/
|   `-- deployment/
|       |-- oracle-cloud.md
|       |-- https.md
|       `-- operations.md
|
|-- nginx/
|   |-- conf.d/
|   |   `-- github-readme-stats.conf
|   `-- nginx.conf
|
|-- scripts/
|   |-- certbot/
|   |   |-- pre-renewal.sh
|   |   `-- post-renewal.sh
|   |
|   |-- backup.sh
|   |-- bootstrap.sh
|   |-- clone.sh
|   |-- common.sh
|   |-- config.sh
|   |-- configure.sh
|   |-- deploy.sh
|   |-- install-certbot-hooks.sh
|   |-- update.sh
|   `-- validate.sh
|
|-- .dockerignore
|-- .editorconfig
|-- .env.example
|-- .gitattributes
|-- .gitignore
|-- CHANGELOG.md
|-- LICENSE
`-- README.md
```

The `deployment/github-readme-stats/` directory contains the runtime
clone of the upstream application and is intentionally excluded from
version control.

## Prerequisites

The production host requires:

-   Ubuntu 24.04 LTS or a compatible Linux environment
-   Bash
-   Git
-   Docker
-   Docker Compose
-   Certbot
-   iptables
-   Internet connectivity
-   A DNS name resolving to the production VM
-   A GitHub Personal Access Token

The deployment scripts perform runtime validation before deployment.

## Environment Configuration

Create the production environment file from the provided template:

``` bash
cp .env.example .env
```

Configure the required values in `.env`.

The deployment uses configuration including:

``` text
PAT_1
DOMAIN_NAME
PORT
HTTP_PORT
HTTPS_PORT
CACHE_SECONDS
ENVIRONMENT
LOG_LEVEL
```

The production domain is configured through:

``` text
DOMAIN_NAME=vishal-github-stats.duckdns.org
```

The GitHub Personal Access Token must never be committed to version
control.

The `.env` file is excluded through `.gitignore`.

## Bootstrap

Run all commands in this section from the repository root:

``` text
/home/ubuntu/github-readme-stats-deployment
```

### Validate the Environment

``` bash
bash scripts/validate.sh
```

### Configure the Workspace

``` bash
bash scripts/configure.sh
```

### Bootstrap the Deployment Workspace

``` bash
bash scripts/bootstrap.sh
```

The bootstrap process validates the environment, prepares required
directories, loads configuration, clones the upstream GitHub Readme
Stats repository, and verifies the resulting deployment workspace.

## Production Deployment

Run from:

``` text
/home/ubuntu/github-readme-stats-deployment
```

Validate the Docker Compose configuration:

``` bash
docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    config --quiet
```

Deploy the application:

``` bash
bash scripts/deploy.sh
```

A successful deployment verifies:

1.  Deployment workspace
2.  Required secrets
3.  Docker runtime
4.  Docker Compose configuration
5.  Application image build
6.  Application container status
7.  Application health
8.  Nginx container status
9.  Nginx health
10. End-to-end HTTPS routing

## HTTPS and TLS

The production deployment uses Nginx for TLS termination.

HTTP traffic received on port 80 is redirected to HTTPS on port 443.

TLS certificates are issued by Let's Encrypt and managed through
Certbot.

Certificate files are stored on the production VM under:

``` text
/etc/letsencrypt/live/vishal-github-stats.duckdns.org/
```

The Nginx container mounts the required Let's Encrypt certificate files
as read-only resources.

Detailed HTTPS documentation is available in:

`docs/deployment/https.md`

## Certbot Renewal Hooks

The deployment uses the Certbot standalone authenticator.

Standalone HTTP-01 validation requires exclusive access to TCP port 80.
The production Nginx service therefore needs to stop temporarily during
certificate validation.

Canonical renewal hooks are maintained in:

``` text
scripts/certbot/pre-renewal.sh
scripts/certbot/post-renewal.sh
```

Install the repository-managed hooks from the production repository
root:

``` bash
sudo bash scripts/install-certbot-hooks.sh
```

Validate the renewal workflow:

``` bash
sudo certbot renew --dry-run
```

The expected workflow is:

``` text
Certbot renewal begins
    |
    v
Pre-renewal hook
    |
    v
Nginx stops
    |
    v
TCP port 80 becomes available
    |
    v
ACME HTTP-01 validation
    |
    v
Post-renewal hook
    |
    v
Nginx starts
    |
    v
HTTP and HTTPS traffic restored
```

## Deployment Verification

### Check Containers

Run from the production repository root:

``` bash
docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    ps
```

Both containers should be running and healthy:

``` text
github-readme-stats
github-readme-stats-nginx
```

### Verify HTTP Redirect

``` bash
curl -I http://vishal-github-stats.duckdns.org
```

Expected response:

``` text
HTTP/1.1 301 Moved Permanently
```

### Verify HTTPS API

``` bash
curl \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    "https://vishal-github-stats.duckdns.org/api?username=Vishal72021"
```

A successful request exits with status code `0`.

## Operations

### Update the Deployment

Run from the production repository root:

``` bash
bash scripts/update.sh
```

### Create a Backup

Run from the production repository root:

``` bash
bash scripts/backup.sh
```

### Check Container Health

``` bash
docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    ps
```

### Check Certificate Status

``` bash
sudo certbot certificates
```

### Check Certificate Renewal Timer

``` bash
systemctl list-timers | grep certbot
```

Detailed operational procedures are documented in:

`docs/deployment/operations.md`

## Firewall and Networking

The production deployment requires inbound access to:

  Port   Protocol   Purpose
  ------ ---------- -------------------------------------------
  22     TCP        SSH administration
  80     TCP        HTTP redirect and ACME HTTP-01 validation
  443    TCP        HTTPS application traffic

Application port `9000` is internal and must not be exposed directly to
the public Internet.

The host firewall is managed through iptables and persisted using
`netfilter-persistent`.

Oracle-provided `InstanceServices` rules must be preserved.

Docker-managed networking rules are recreated by Docker and should not
be stored as part of the host-only persistent firewall rules.

## Automatic Recovery

The production VM is configured for automatic service recovery.

Docker is enabled at system startup.

The application and Nginx containers use:

``` text
restart: unless-stopped
```

The host firewall is restored through `netfilter-persistent`.

Following a VM reboot, the expected recovery path is:

``` text
VM boots
    |
    v
Persistent host firewall loads
    |
    v
Docker daemon starts
    |
    v
Docker networking is recreated
    |
    v
Application container starts
    |
    v
Nginx container starts
    |
    v
Health checks pass
    |
    v
HTTPS service becomes available
```

## Security

The deployment follows several production security practices:

-   Public traffic is encrypted with HTTPS.
-   HTTP traffic is redirected to HTTPS.
-   TLS certificates are issued by Let's Encrypt.
-   Certificate files are mounted read-only into Nginx.
-   The application container is not directly exposed publicly.
-   Public ingress is restricted to required ports.
-   GitHub Personal Access Tokens are stored in `.env`.
-   `.env` is excluded from version control.
-   Host firewall rules protect the production VM.
-   Oracle Cloud networking rules provide an additional network security
    layer.
-   Deployment validation checks required secrets without printing
    secret values.

Never commit:

-   `.env`
-   GitHub Personal Access Tokens
-   TLS private keys
-   SSH private keys
-   Production credentials

## Documentation

Detailed documentation is maintained under `docs/`.

  -----------------------------------------------------------------------
  Document                            Purpose
  ----------------------------------- -----------------------------------
  `docs/deployment/oracle-cloud.md`   Oracle Cloud infrastructure and
                                      networking

  `docs/deployment/https.md`          HTTPS, TLS, and certificate
                                      management

  `docs/deployment/operations.md`     Production operations, validation,
                                      and recovery

  `scripts/README.md`                 Deployment automation script
                                      documentation
  -----------------------------------------------------------------------

## Development Workflow

The project follows a controlled engineering workflow:

``` text
Design
    |
    v
Architecture Review
    |
    v
Freeze Architecture
    |
    v
Implementation
    |
    v
Validation
    |
    v
Production Deployment
    |
    v
Documentation
    |
    v
Versioned Release
```

Changes should be validated locally before being committed and deployed.

Production changes should be applied through the repository whenever
possible so the repository remains the source of truth for deployment
infrastructure.

## Versioning

This project follows Semantic Versioning:

``` text
MAJOR.MINOR.PATCH
```

-   `MAJOR` --- incompatible changes
-   `MINOR` --- backward-compatible functionality
-   `PATCH` --- backward-compatible fixes

## Changelog

Project changes are documented in:

`CHANGELOG.md`

The changelog follows the Keep a Changelog structure.

## Contributing

Contributions should follow the repository engineering and contribution
standards defined in:

`.github/CONTRIBUTING.md`

Before submitting changes:

1.  Follow the established repository architecture.
2.  Validate shell scripts and configuration.
3.  Do not commit secrets or environment files.
4.  Update documentation when behavior changes.
5.  Update `CHANGELOG.md` for notable changes.

## Security Policy

Security vulnerabilities should be reported according to:

`.github/SECURITY.md`

Do not disclose production credentials, GitHub tokens, SSH keys, or TLS
private keys in public issues.

## License

This deployment repository is licensed under the terms provided in:

`LICENSE`

The upstream GitHub Readme Stats project is maintained separately and
remains subject to its own license and project terms.

## Acknowledgements

This project deploys and operates the upstream GitHub Readme Stats
application.

Credit for the application itself belongs to the GitHub Readme Stats
project and its contributors.

This repository focuses on the surrounding self-hosted production
deployment infrastructure, automation, security, TLS, reverse proxying,
operations, and recovery lifecycle.
