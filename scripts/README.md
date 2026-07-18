# Deployment Scripts

This directory contains the automation and lifecycle management scripts for the
GitHub Readme Stats deployment platform.

The scripts provide a structured operational framework for validating the host
environment, configuring the workspace, cloning the upstream application,
bootstrapping the project, deploying the containerized application, creating
source backups, and safely applying upstream updates.

---

## Directory Structure

```text
scripts/
├── common.sh
├── config.sh
├── validate.sh
├── configure.sh
├── clone.sh
├── bootstrap.sh
├── deploy.sh
├── backup.sh
├── update.sh
└── README.md
```

---

## Architecture

The scripts are organized around clear responsibility boundaries.

```text
                  common.sh
                      │
                  config.sh
                      │
          ┌───────────┼───────────┐
          ▼           ▼           ▼
     validate.sh configure.sh  clone.sh
          │           │           │
          └───────────┼───────────┘
                      ▼
                 bootstrap.sh

                      │
                      ▼
                  deploy.sh

                 backup.sh
                      │
                      ▼
                  update.sh
                 ┌────┴────┐
                 ▼         ▼
             backup.sh  deploy.sh
```

Individual lifecycle scripts own one primary operational responsibility.

Orchestration scripts reuse existing lifecycle scripts rather than duplicating
their implementation.

---

## Script Responsibility Matrix

| Script | Responsibility |
| --- | --- |
| `common.sh` | Shared logging, formatting, environment loading, retry, and error-handling utilities |
| `config.sh` | Central project constants, paths, upstream configuration, defaults, and operational policies |
| `validate.sh` | Validates host tools, supported versions, network connectivity, and environment files |
| `configure.sh` | Creates required directories, prepares `.env`, loads configuration, and validates runtime values |
| `clone.sh` | Clones, validates, fetches, checks out, and safely updates the upstream repository |
| `bootstrap.sh` | Orchestrates validation, configuration, repository setup, and bootstrap verification |
| `deploy.sh` | Builds and deploys the application and verifies container and application health |
| `backup.sh` | Creates, verifies, documents, and retains timestamped source backups |
| `update.sh` | Detects upstream changes, creates a pre-update backup, safely updates the repository, and redeploys the application |

---

# Shared Foundation

## `common.sh`

`common.sh` contains reusable shell utilities shared across the deployment
framework.

Typical responsibilities include:

- Script header formatting.
- Section formatting.
- Separator formatting.
- Timestamped logging.
- Informational messages.
- Warning messages.
- Success messages.
- Error messages.
- Fatal error handling.
- Environment-file loading.
- Command retry handling.

Lifecycle scripts source this file instead of implementing their own logging and
utility functions.

`common.sh` contains reusable behavior but does not own project-specific
configuration or deployment lifecycle logic.

---

## `config.sh`

`config.sh` is the centralized configuration layer for the deployment
framework.

It defines project-level constants such as:

- Project name.
- Project slug.
- Project version.
- Project root.
- Upstream repository.
- Upstream branch.
- Upstream remote.
- Deployment directory.
- Repository directory.
- Backup directory.
- Log directory.
- Docker directory.
- Compose directory.
- Environment-file paths.
- Required environment keys.
- Minimum supported tool versions.
- Retry configuration.
- Network validation targets.
- Default runtime values.
- Backup retention policy.
- Deployment service and container configuration.

The file intentionally contains configuration rather than operational logic.

User-specific runtime configuration belongs in:

```text
.env
```

Safe configuration documentation belongs in:

```text
.env.example
```

Secrets must never be stored directly in `config.sh`.

---

# Environment Validation

## `validate.sh`

`validate.sh` verifies that the host environment satisfies the requirements of
the deployment platform.

The validation lifecycle includes checks for:

```text
Bash
  ↓
Git
  ↓
Docker
  ↓
Docker Compose
  ↓
Network Connectivity
  ↓
.env.example
  ↓
.env
```

The script reports:

- Successful checks.
- Warnings.
- Failures.
- Environment diagnostics.
- Tool versions.

Validation failures prevent the bootstrap lifecycle from continuing.

### Usage

Run from the project root:

```bash
bash scripts/validate.sh
```

---

# Workspace Configuration

## `configure.sh`

`configure.sh` prepares the local deployment workspace.

Its responsibilities include:

- Creating required project directories.
- Preparing the runtime `.env` file.
- Loading environment configuration.
- Validating required configuration keys.
- Validating configuration values.
- Printing a safe configuration summary.

The script never prints the actual value of `PAT_1`.

Instead, secret configuration is reported only as configured or missing.

### Usage

Run from the project root:

```bash
bash scripts/configure.sh
```

---

# Repository Management

## `clone.sh`

`clone.sh` manages the local checkout of the upstream GitHub Readme Stats
repository.

The upstream application is cloned into:

```text
deployment/github-readme-stats/
```

The lifecycle includes:

```text
Repository Setup
      ↓
Repository Verification
      ↓
Remote Verification
      ↓
Fetch
      ↓
Branch Checkout
      ↓
Fast-Forward Update
      ↓
Repository Summary
```

The script supports repeated execution.

If the repository does not exist, it is cloned.

If the repository already exists, it is validated and updated.

If the target path exists but is not a Git repository, the script fails rather
than overwriting the directory.

If the configured remote does not match the expected upstream repository, the
script fails safely.

Repository updates use fast-forward-only behavior to avoid unexpected merge
commits.

### Usage

Run from the project root:

```bash
bash scripts/clone.sh
```

---

# Project Bootstrap

## `bootstrap.sh`

`bootstrap.sh` is the primary first-time project initialization entry point.

It orchestrates:

```text
validate.sh
      ↓
configure.sh
      ↓
clone.sh
      ↓
Bootstrap Verification
```

The script verifies that the complete deployment workspace is ready before
reporting success.

The bootstrap layer does not deploy the application.

Deployment remains the responsibility of `deploy.sh`.

### Usage

Run from the project root:

```bash
bash scripts/bootstrap.sh
```

For a fresh environment, this should normally be the first lifecycle command
executed after creating the required runtime configuration.

---

# Application Deployment

## `deploy.sh`

`deploy.sh` owns the application deployment lifecycle.

Its responsibilities include:

- Verifying the deployment workspace.
- Validating deployment secrets.
- Verifying the Docker runtime.
- Validating the Docker Compose configuration.
- Building the application image.
- Starting or reconciling the application service.
- Verifying the running container.
- Waiting for container health.
- Verifying application HTTP reachability.
- Printing the deployment summary.

The deployment flow is:

```text
Verify Deployment Workspace
      ↓
Validate Deployment Secrets
      ↓
Verify Docker Runtime
      ↓
Validate Compose Configuration
      ↓
Build Application Image
      ↓
Start Application Service
      ↓
Verify Container
      ↓
Verify Container Health
      ↓
Verify Application Reachability
      ↓
Deployment Complete
```

The script uses:

```text
compose/docker-compose.yml
```

for service orchestration and:

```text
docker/Dockerfile
```

for image construction.

### Usage

Run from the project root:

```bash
bash scripts/deploy.sh
```

Repeated deployments are supported.

---

# Repository Backups

## `backup.sh`

`backup.sh` creates verified source backups of the current upstream repository
state.

The backup lifecycle is:

```text
Verify Backup Workspace
      ↓
Verify Repository State
      ↓
Capture Repository Metadata
      ↓
Create Timestamped Backup
      ↓
Verify Archive Integrity
      ↓
Verify Metadata
      ↓
Apply Retention Policy
      ↓
Print Backup Summary
```

Backups are stored under:

```text
backups/
```

Each backup uses a UTC timestamp:

```text
backups/
└── YYYYMMDDTHHMMSSZ/
    ├── github-readme-stats.tar.gz
    └── metadata.env
```

The source archive excludes the repository `.git` directory.

Git recovery information is stored separately in `metadata.env`.

Metadata includes:

```text
BACKUP_TIMESTAMP
REPOSITORY_NAME
REPOSITORY_BRANCH
REPOSITORY_COMMIT
REPOSITORY_REMOTE
```

The backup does not contain the deployment `.env` file or GitHub Personal Access
Token.

Before creating a backup, the script verifies:

- The repository exists.
- The repository is valid.
- The configured remote is correct.
- The repository is on the expected branch.
- The working tree is clean.

Incomplete or invalid backups are not considered successful.

The retention policy automatically removes backups exceeding the configured
retention count.

### Usage

Run from the project root:

```bash
bash scripts/backup.sh
```

---

# Application Updates

## `update.sh`

`update.sh` provides the safe upstream application update lifecycle.

It combines repository verification, update detection, backup creation, Git
fast-forward operations, and application redeployment.

The lifecycle is:

```text
Verify Update Workspace
      ↓
Verify Repository State
      ↓
Fetch Upstream
      ↓
Detect Update
      │
      ├── No Update
      │      ↓
      │   Exit Successfully
      │
      └── Update Available
             ↓
      Create Pre-Update Backup
             ↓
      Fast-Forward Repository
             ↓
      Verify Updated Commit
             ↓
      Redeploy Application
             ↓
      Verify Deployment
             ↓
      Print Update Summary
```

The script refuses to update when:

- The repository is missing.
- The repository is invalid.
- The remote does not match the expected upstream repository.
- The repository is on the wrong branch.
- The working tree contains local modifications.
- The local and upstream histories cannot be safely fast-forwarded.
- The pre-update backup fails.

The update operation does not use destructive commands such as:

```text
git reset --hard
git push --force
```

A verified backup must complete before repository modification is allowed.

Repository updates target the exact upstream commit detected during the fetch
phase.

After updating, `update.sh` invokes:

```text
deploy.sh
```

to rebuild, redeploy, and verify the updated application.

### Usage

Run from the project root:

```bash
bash scripts/update.sh
```

If no upstream changes are available, the script exits successfully without
creating an unnecessary backup or redeploying the application.

---

# Recommended Operational Workflow

## First-Time Setup

From the project root:

```bash
bash scripts/bootstrap.sh
```

Then deploy:

```bash
bash scripts/deploy.sh
```

The complete first-time lifecycle is:

```text
bootstrap.sh
    │
    ├── validate.sh
    ├── configure.sh
    └── clone.sh
            │
            ▼
        deploy.sh
```

---

## Manual Backup

Before maintenance or other potentially significant operations:

```bash
bash scripts/backup.sh
```

---

## Application Update

To check for and safely apply upstream updates:

```bash
bash scripts/update.sh
```

The update script automatically creates a pre-update backup when an update is
available.

---

# Script Invocation

Scripts should be executed from the project root.

Example project root:

```text
github-readme-stats-deployment/
```

Recommended invocation:

```bash
bash scripts/<script-name>.sh
```

This invocation style works consistently with the project's Windows and WSL
development workflow and does not depend on executable permission bits being
preserved by the Windows filesystem.

---

# Syntax Validation

All scripts can be syntax-validated from the project root with:

```bash
bash -n scripts/common.sh
bash -n scripts/config.sh
bash -n scripts/validate.sh
bash -n scripts/configure.sh
bash -n scripts/clone.sh
bash -n scripts/bootstrap.sh
bash -n scripts/deploy.sh
bash -n scripts/backup.sh
bash -n scripts/update.sh
```

Successful syntax validation produces no output.

---

# Failure Handling

The scripts follow fail-fast behavior using strict Bash execution:

```bash
set -Eeuo pipefail
```

Lifecycle operations stop when required prerequisites fail.

Critical operations use explicit validation and error reporting rather than
silently continuing after failures.

The deployment framework is designed around the principle:

```text
Validate
    ↓
Verify Preconditions
    ↓
Perform Operation
    ↓
Verify Result
    ↓
Report Success
```

A successful command exit therefore indicates that the corresponding lifecycle
operation completed its verification steps.

---

# Retry Behavior

Operations that may fail temporarily because of external dependencies can use
the shared retry mechanism provided by `common.sh`.

Examples include:

- Repository network operations.
- External connectivity operations.

Retry configuration is centralized in:

```text
scripts/config.sh
```

This prevents individual scripts from implementing inconsistent retry behavior.

---

# Security

The scripts follow several security rules.

## Secrets

The GitHub Personal Access Token is stored in:

```text
.env
```

It must never be:

- Committed to Git.
- Hardcoded in shell scripts.
- Stored in `config.sh`.
- Included in backup archives.
- Printed in logs.
- Included in documentation.

The safe template:

```text
.env.example
```

contains the required key but no real secret value.

## Repository Protection

Repository update operations:

- Require a clean working tree.
- Verify the expected remote.
- Verify the expected branch.
- Require fast-forward-compatible history.
- Avoid destructive Git resets.

## Backup Protection

Backups:

- Exclude deployment secrets.
- Are integrity-checked after creation.
- Record the exact source commit.
- Are subject to a defined retention policy.

## Deployment Protection

Deployments:

- Validate required secrets before startup.
- Validate Docker Compose configuration.
- Verify container runtime status.
- Verify application health before reporting success.

---

# Responsibility Boundaries

The scripts layer owns:

```text
Environment validation
Workspace configuration
Repository lifecycle
Bootstrap orchestration
Deployment orchestration
Backup lifecycle
Update lifecycle
Operational verification
```

The scripts layer does not own:

```text
Application source implementation
Docker image implementation
Container runtime implementation
Docker Compose service definition
Reverse proxy configuration
CI/CD pipeline execution
Production infrastructure provisioning
```

Those responsibilities belong to their respective project layers.

---

# Related Project Components

```text
github-readme-stats-deployment/
│
├── scripts/
│   └── Lifecycle automation
│
├── docker/
│   └── Container image and runtime
│
├── compose/
│   └── Container orchestration
│
├── deployment/
│   └── Runtime upstream source checkout
│
├── backups/
│   └── Runtime source backups
│
├── logs/
│   └── Runtime logs
│
├── .env
│   └── Local runtime configuration and secrets
│
└── .env.example
    └── Safe configuration template
```

---

# Operational Entry Points

For normal operation, the primary commands are:

```bash
# Initialize the deployment workspace.
bash scripts/bootstrap.sh

# Deploy the application.
bash scripts/deploy.sh

# Create a manual backup.
bash scripts/backup.sh

# Check for updates and safely deploy them.
bash scripts/update.sh
```

Individual scripts such as `validate.sh`, `configure.sh`, and `clone.sh` remain
available for direct troubleshooting and targeted lifecycle operations.

---

# Architecture Status

The scripts architecture is frozen for version `1.0.0`.

The current implementation provides:

```text
Shared Utilities        ✅
Central Configuration   ✅
Environment Validation  ✅
Workspace Configuration ✅
Repository Management   ✅
Bootstrap Orchestration ✅
Deployment Automation   ✅
Backup Management       ✅
Safe Update Automation  ✅
```

Future changes should preserve the established responsibility boundaries and
avoid duplicating lifecycle logic between scripts.