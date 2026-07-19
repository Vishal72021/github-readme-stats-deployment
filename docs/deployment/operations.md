# Production Operations

## Overview

This document describes the operational procedures for managing,
validating, monitoring, and recovering the production GitHub Readme
Stats deployment.

The production deployment is hosted on an Oracle Cloud Compute instance
and uses Docker Compose to manage the application and Nginx reverse
proxy.

## Production Environment

Production domain:

`vishal-github-stats.duckdns.org`

Production deployment directory:

`/home/ubuntu/github-readme-stats-deployment`

The production stack consists of:

-   GitHub Readme Stats application container
-   Nginx reverse proxy container
-   Docker Compose orchestration
-   Let's Encrypt TLS certificates
-   Certbot automatic certificate renewal
-   Persistent host firewall configuration

## Connect to the Production VM

Connect from the local development machine:

``` powershell
ssh -i "D:\secrets\ssh-key-2026-07-19.key" ubuntu@68.233.98.192
```

After connecting:

``` bash
cd ~/github-readme-stats-deployment
```

## Validate the Deployment Environment

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
bash scripts/validate.sh
```

The validation must complete without failures before deployment.

## Configure the Deployment Workspace

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
bash scripts/configure.sh
```

The production `.env` file must contain all required deployment
configuration, including the production domain.

## Validate Docker Compose Configuration

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    config --quiet
```

A successful validation exits without output.

## Deploy the Application

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
bash scripts/deploy.sh
```

The deployment process verifies the workspace and secrets, validates
Docker Compose, builds the application image, starts the stack, checks
both container health states, and verifies the public HTTPS route.

## Check Container Status

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    ps
```

Both `github-readme-stats` and `github-readme-stats-nginx` should be
running and healthy.

## Validate HTTP-to-HTTPS Redirect

Run from any machine with Internet access:

``` bash
curl -I http://vishal-github-stats.duckdns.org
```

Expected response:

``` text
HTTP/1.1 301 Moved Permanently
```

The `Location` header should point to
`https://vishal-github-stats.duckdns.org/`.

## Validate the HTTPS API

Run from any machine with Internet access:

``` bash
curl \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    "https://vishal-github-stats.duckdns.org/api?username=Vishal72021"
```

A successful request exits with status code `0`.

## Check TLS Certificates

Run on the production VM:

``` bash
sudo certbot certificates
```

Verify that the certificate is valid and contains the expected
production domain.

## Check Certbot Automatic Renewal

Run on the production VM:

``` bash
systemctl list-timers | grep certbot
```

The Certbot timer should be scheduled.

Check it directly with:

``` bash
sudo systemctl status certbot.timer --no-pager
```

## Validate Certificate Renewal

Run on the production VM:

``` bash
sudo certbot renew --dry-run
```

A successful renewal test should stop Nginx, release TCP port 80,
complete the simulated ACME HTTP-01 challenge, start Nginx again, and
restore HTTP and HTTPS availability.

After the renewal test:

``` bash
cd ~/github-readme-stats-deployment

docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    ps
```

## Install Certbot Renewal Hooks

Canonical Certbot renewal hooks are stored in the repository.

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
sudo bash scripts/install-certbot-hooks.sh
```

The installer installs the repository-managed hooks under
`/etc/letsencrypt/renewal-hooks/`.

After installation:

``` bash
sudo certbot renew --dry-run
```

## Check Docker Service

``` bash
sudo systemctl status docker --no-pager
```

Verify Docker starts automatically:

``` bash
sudo systemctl is-enabled docker
```

Expected result:

``` text
enabled
```

## Check Container Restart Policies

Run from `/home/ubuntu/github-readme-stats-deployment`:

``` bash
docker inspect \
    --format '{{.Name}} -> {{.HostConfig.RestartPolicy.Name}}' \
    github-readme-stats \
    github-readme-stats-nginx
```

Expected restart policy:

``` text
unless-stopped
```

## Check Host Firewall

``` bash
sudo iptables -L INPUT -n -v --line-numbers
```

Verify inbound TCP traffic is permitted for:

-   Port 22 --- SSH
-   Port 80 --- HTTP and ACME validation
-   Port 443 --- HTTPS

The ACCEPT rules must appear before the final host-level REJECT rule.

## Check Persistent Firewall Service

``` bash
sudo systemctl is-enabled netfilter-persistent
```

Expected result:

``` text
enabled
```

Verify service status:

``` bash
sudo systemctl status netfilter-persistent --no-pager
```

## Validate Persistent Firewall Configuration

``` bash
sudo grep -E -- "-A INPUT.*--dport (22|80|443)" \
    /etc/iptables/rules.v4
```

Docker-managed rules should not be stored in the host-only persistent
firewall configuration.

``` bash
sudo grep -E "DOCKER|docker0|br-[a-f0-9]+" \
    /etc/iptables/rules.v4 \
    || echo "Persistent IPv4 rules contain no Docker-managed rules"
```

## Validate Persistent Firewall Syntax

Because `/etc/iptables/rules.v4` is readable only by root, execute the
entire redirection through a privileged shell:

``` bash
sudo sh -c 'iptables-restore --test < /etc/iptables/rules.v4'
```

Check the exit status:

``` bash
echo $?
```

Expected result:

``` text
0
```

## Recovery After VM Reboot

After rebooting the Oracle Cloud VM:

1.  Reconnect through SSH.
2.  Verify `netfilter-persistent` loaded the host firewall.
3.  Verify Docker started automatically.
4.  Verify Docker recreated its networking rules.
5.  Verify the application container is running and healthy.
6.  Verify the Nginx container is running and healthy.
7.  Verify HTTP redirects to HTTPS.
8.  Verify the HTTPS API returns a successful response.

Check the containers:

``` bash
cd ~/github-readme-stats-deployment

docker compose \
    --env-file .env \
    -f compose/docker-compose.yml \
    ps
```

Check HTTP redirect:

``` bash
curl -I http://vishal-github-stats.duckdns.org
```

Check HTTPS API:

``` bash
curl \
    --fail \
    --silent \
    --show-error \
    --output /dev/null \
    "https://vishal-github-stats.duckdns.org/api?username=Vishal72021"
```

## Production Health Checklist

A healthy production deployment must satisfy all of the following:

-   Docker service is active.
-   Docker service is enabled at boot.
-   Application container is running and healthy.
-   Nginx container is running and healthy.
-   Container restart policies are `unless-stopped`.
-   TCP ports 22, 80, and 443 are accessible as required.
-   HTTP requests redirect to HTTPS.
-   HTTPS API requests succeed.
-   TLS certificate is valid.
-   Certbot automatic renewal timer is enabled.
-   Certbot renewal dry-run succeeds.
-   Host firewall configuration persists across reboot.
-   Docker networking is recreated correctly after reboot.
