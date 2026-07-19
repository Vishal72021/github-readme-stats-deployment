# HTTPS and TLS

## Overview

The production deployment uses Nginx for TLS termination and Let's Encrypt for
TLS certificate issuance.

Production domain:

`vishal-github-stats.duckdns.org`

## Request Flow

HTTP requests follow this path:

Client → Port 80 → Nginx → HTTP 301 redirect → HTTPS

HTTPS requests follow this path:

Client → Port 443 → Nginx TLS termination → GitHub Readme Stats application

The application container listens internally on port `9000` and is not exposed
directly to the public Internet.

## Certificates

TLS certificates are managed by Certbot and Let's Encrypt.

Certificate files are stored under:

`/etc/letsencrypt/live/vishal-github-stats.duckdns.org/`

Nginx mounts the Let's Encrypt certificate directory as read-only.

## Certificate Renewal

The certificate uses the Certbot `standalone` authenticator.

The standalone HTTP-01 challenge requires exclusive access to TCP port 80.
Because Nginx normally owns port 80, Certbot renewal hooks temporarily stop the
Nginx service before validation and start it again afterward.

Canonical hook sources are stored in:

- `scripts/certbot/pre-renewal.sh`
- `scripts/certbot/post-renewal.sh`

Hook installation is managed by:

`scripts/install-certbot-hooks.sh`

The Certbot systemd timer performs scheduled renewal checks.

## Renewal Validation

After installing or modifying the renewal hooks, validate renewal with:

```bash
sudo certbot renew --dry-run