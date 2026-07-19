# Changelog

All notable changes to this project will be documented in this file.

The format is based on **Keep a Changelog** and this project adheres to
**Semantic Versioning (SemVer)**.

------------------------------------------------------------------------

## \[Unreleased\]

### Added

-   None.

### Changed

-   None.

### Deprecated

-   None.

### Removed

-   None.

### Fixed

-   None.

### Security

-   None.

------------------------------------------------------------------------

## \[1.0.0\] - 2026-07-19

### Added

#### Production Deployment

-   Added production deployment support for Oracle Cloud Infrastructure.
-   Added production deployment using an Oracle Cloud Compute instance
    running Ubuntu 24.04 LTS.
-   Added public domain configuration through `DOMAIN_NAME`.
-   Added HTTPS port configuration through `HTTPS_PORT`.
-   Added production deployment documentation for Oracle Cloud
    infrastructure.
-   Added production operations and recovery documentation.

#### HTTPS and TLS

-   Added HTTPS support through the Nginx reverse proxy.
-   Added TLS termination using Let's Encrypt certificates.
-   Added HTTP-to-HTTPS redirection.
-   Added production domain support for
    `vishal-github-stats.duckdns.org`.
-   Added read-only Let's Encrypt certificate mounts for the Nginx
    container.
-   Added HTTPS-aware end-to-end deployment verification.
-   Added TLS certificate and renewal documentation.

#### Certificate Renewal Automation

-   Added repository-managed Certbot pre-renewal hook.
-   Added repository-managed Certbot post-renewal hook.
-   Added `scripts/install-certbot-hooks.sh` for reproducible Certbot
    hook installation.
-   Added automatic Nginx shutdown before standalone ACME HTTP-01
    validation.
-   Added automatic Nginx startup after certificate renewal attempts.
-   Added validation and structured logging to Certbot renewal hooks.
-   Added backup handling for existing project-managed renewal hooks.
-   Added Certbot renewal dry-run validation procedures.

#### Production Networking and Recovery

-   Added persistent host firewall configuration for SSH, HTTP, and
    HTTPS traffic.
-   Added production firewall persistence using `netfilter-persistent`.
-   Added documented preservation of Oracle Cloud `InstanceServices`
    firewall rules.
-   Added documented separation between persistent host firewall rules
    and Docker-managed networking rules.
-   Added Docker container restart policies for automatic recovery.
-   Added VM reboot recovery and production health verification
    procedures.

### Changed

#### Deployment Configuration

-   Extended deployment configuration to require and validate
    `DOMAIN_NAME`.
-   Added `HTTPS_PORT` to production configuration.
-   Updated configuration summaries to display the production domain and
    HTTPS port.
-   Updated deployment summaries to display the production HTTPS URL.
-   Updated the application URL from a localhost HTTP endpoint to the
    public HTTPS domain.

#### Reverse Proxy

-   Updated Nginx configuration for production domain routing.
-   Updated Nginx to listen for HTTPS traffic on port 443.
-   Updated Nginx to terminate TLS using Let's Encrypt certificates.
-   Updated HTTP traffic on port 80 to redirect to HTTPS.
-   Preserved the internal application service on port 9000 without
    direct public exposure.

#### Deployment Validation

-   Updated reverse proxy route verification to validate the public
    HTTPS endpoint.
-   Updated deployment validation to support production domain
    configuration.
-   Extended deployment verification to validate the complete HTTPS
    request path.

#### Documentation

-   Added dedicated Oracle Cloud deployment documentation.
-   Added dedicated HTTPS and TLS documentation.
-   Added comprehensive production operations documentation.
-   Documented certificate renewal procedures.
-   Documented firewall persistence and validation procedures.
-   Documented production VM reboot and recovery procedures.

### Deprecated

-   None.

### Removed

-   None.

### Fixed

#### Networking

-   Fixed host-level firewall rules that prevented inbound HTTP and
    HTTPS traffic.
-   Fixed external connectivity to TCP ports 80 and 443.
-   Fixed Certbot standalone HTTP-01 validation failure caused by
    inaccessible port 80.

#### Certificate Renewal

-   Fixed Certbot standalone renewal workflow by releasing port 80
    before ACME validation.
-   Fixed Nginx restoration after certificate renewal attempts through
    post-renewal hooks.

#### Deployment

-   Fixed reverse proxy validation to use the production HTTPS endpoint
    instead of localhost HTTP.
-   Fixed production deployment summaries to report the configured
    public domain and HTTPS endpoint.

### Security

-   Enabled HTTPS for all public application traffic.
-   Added HTTP-to-HTTPS redirection.
-   Added trusted TLS certificates issued by Let's Encrypt.
-   Restricted public application access to Nginx through ports 80 and
    443.
-   Kept the application service port 9000 isolated from direct public
    access.
-   Preserved Oracle Cloud host firewall protections.
-   Added persistent host firewall rules for required production ports.
-   Configured Let's Encrypt certificate storage as read-only inside the
    Nginx container.
-   Added automated TLS certificate renewal support.

------------------------------------------------------------------------

## \[0.1.0\] - 2026-07-17

### Added

#### Repository Foundation

-   Established production-ready repository structure.
-   Added repository engineering standards.
-   Added GitHub community health files.
-   Added Docker deployment structure.
-   Added Docker Compose structure.
-   Added Nginx deployment structure.
-   Added deployment automation scripts.
-   Added documentation framework.
-   Added project license.
-   Added repository metadata.

#### GitHub Community Standards

-   Added `CODEOWNERS`.
-   Added `CONTRIBUTING.md`.
-   Added `PULL_REQUEST_TEMPLATE.md`.
-   Added `SECURITY.md`.
-   Added issue templates.
-   Added workflow directory structure.

#### Engineering Standards

-   Added `.gitignore`.
-   Added `.editorconfig`.
-   Added `.gitattributes`.
-   Added `.env.example`.

------------------------------------------------------------------------

## Versioning

This project follows **Semantic Versioning**.

Given a version number:

``` text
MAJOR.MINOR.PATCH
```

-   **MAJOR** --- Incompatible changes.
-   **MINOR** --- New functionality added in a backward-compatible
    manner.
-   **PATCH** --- Backward-compatible bug fixes.

Examples:

``` text
1.0.0
1.1.0
1.1.1
2.0.0
```

------------------------------------------------------------------------

## Change Categories

The following categories are used throughout this changelog:

  Category     Description
  ------------ -----------------------------------
  Added        New functionality
  Changed      Updates to existing functionality
  Deprecated   Features scheduled for removal
  Removed      Removed functionality
  Fixed        Bug fixes
  Security     Security improvements

------------------------------------------------------------------------

## References

-   Keep a Changelog
-   Semantic Versioning
