# Oracle Cloud Deployment

## Overview

This document describes the Oracle Cloud Infrastructure used to host the
GitHub Readme Stats deployment.

## Compute

The production deployment runs on an Oracle Cloud Compute instance with the
following configuration:

- Operating system: Ubuntu 24.04 LTS
- Architecture: x86_64
- Shape: VM.Standard.E2.1.Micro
- Public IPv4 address enabled
- Boot volume encryption in transit enabled

## Networking

The deployment uses a dedicated Virtual Cloud Network with:

- A public subnet
- An Internet Gateway
- A route table allowing Internet access
- Security rules permitting required inbound traffic

Required inbound TCP ports:

| Port | Purpose |
| --- | --- |
| 22 | SSH administration |
| 80 | HTTP and ACME HTTP-01 validation |
| 443 | HTTPS application traffic |

Application port `9000` is not exposed publicly. It is accessible only inside
the Docker network through the Nginx reverse proxy.

## Host Firewall

The Ubuntu host firewall uses iptables.

Required inbound rules allow:

- TCP 22
- TCP 80
- TCP 443

The ACCEPT rules must appear before the final host-level REJECT rule.

Firewall persistence is managed by `netfilter-persistent`.

Docker-generated chains and NAT rules must not be stored as part of the
host-only persistent firewall configuration. Docker recreates its networking
rules when the Docker daemon starts.

Oracle-provided `InstanceServices` rules must be preserved.

## Docker Recovery

Docker is configured to start automatically during system boot.

The application and Nginx containers use the `unless-stopped` restart policy,
allowing the deployment to recover automatically after a VM reboot.

## Reboot Verification

A successful reboot recovery must verify:

1. SSH connectivity is restored.
2. TCP ports 22, 80, and 443 are permitted by the host firewall.
3. Docker is active.
4. Docker networking rules are recreated.
5. The application container is healthy.
6. The Nginx container is healthy.
7. HTTP redirects to HTTPS.
8. The HTTPS API endpoint returns HTTP 200.