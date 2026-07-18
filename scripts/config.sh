#!/usr/bin/env bash

###############################################################################
# Project Configuration
#
# Centralized project constants used throughout the deployment framework.
#
# Responsibilities
#   - Project metadata
#   - Filesystem paths
#   - Deployment constants
#   - Validation requirements
#   - Default runtime values
#
# This file intentionally contains NO deployment logic.
# User-editable runtime configuration belongs in .env.
###############################################################################

###############################################################################
# Project Metadata
###############################################################################

readonly PROJECT_NAME="GitHub Readme Stats Deployment"
readonly PROJECT_SLUG="github-readme-stats-deployment"
readonly PROJECT_VERSION="1.0.0"

###############################################################################
# Project Paths
#
# NOTE:
# SCRIPT_DIR is provided by the calling script before sourcing config.sh.
###############################################################################

readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

###############################################################################
# Docker Paths
###############################################################################

readonly DOCKER_DIRECTORY="${PROJECT_ROOT}/docker"

readonly DOCKERFILE="${DOCKER_DIRECTORY}/Dockerfile"
readonly DOCKER_ENTRYPOINT="${DOCKER_DIRECTORY}/entrypoint.sh"
readonly DOCKER_HEALTHCHECK="${DOCKER_DIRECTORY}/healthcheck.sh"

###############################################################################
# Docker Compose Paths
###############################################################################

readonly COMPOSE_DIRECTORY="${PROJECT_ROOT}/compose"

readonly COMPOSE_FILE="${COMPOSE_DIRECTORY}/docker-compose.yml"

###############################################################################
# Docker Compose Services
###############################################################################

readonly APPLICATION_SERVICE="github-readme-stats"
readonly APPLICATION_CONTAINER="github-readme-stats"

readonly PROXY_SERVICE="nginx"
readonly PROXY_CONTAINER="github-readme-stats-nginx"

###############################################################################
# Application Health
###############################################################################

readonly HEALTH_CHECK_PATH="/api/"
readonly HEALTH_CHECK_RETRIES=10
readonly HEALTH_CHECK_DELAY=3

###############################################################################
# Container Health
###############################################################################

readonly CONTAINER_HEALTH_RETRIES=12
readonly CONTAINER_HEALTH_DELAY=5

###############################################################################
# Upstream Repository
###############################################################################

readonly UPSTREAM_REPOSITORY="https://github.com/anuraghazra/github-readme-stats.git"
readonly UPSTREAM_BRANCH="master"
readonly UPSTREAM_REMOTE="origin"

###############################################################################
# Deployment Directories
###############################################################################

readonly DEPLOYMENT_DIRECTORY="${PROJECT_ROOT}/deployment"

readonly REPOSITORY_NAME="github-readme-stats"

readonly REPOSITORY_DIRECTORY="${DEPLOYMENT_DIRECTORY}/${REPOSITORY_NAME}"

readonly BACKUP_DIRECTORY="${PROJECT_ROOT}/backups"
readonly LOG_DIRECTORY="${PROJECT_ROOT}/logs"

###############################################################################
# Environment Files
###############################################################################

readonly ENV_FILE="${PROJECT_ROOT}/.env"
readonly ENV_EXAMPLE_FILE="${PROJECT_ROOT}/.env.example"

###############################################################################
# Required Environment Variables
#
# These keys must exist in both:
#   - .env.example
#   - .env (once generated)
###############################################################################

readonly REQUIRED_ENV_KEYS=(
    PAT_1
    PORT
    HTTP_PORT
    CACHE_SECONDS
    ENVIRONMENT
    LOG_LEVEL
)

###############################################################################
# Required Deployment Secrets
###############################################################################

readonly REQUIRED_DEPLOYMENT_SECRETS=(
    PAT_1
)

###############################################################################
# Required Deployment Files
###############################################################################

readonly REQUIRED_DEPLOYMENT_FILES=(
    ".env.example"
)

###############################################################################
# Required Deployment Directories
###############################################################################

readonly REQUIRED_DEPLOYMENT_DIRECTORIES=(
    "scripts"
    "deployment"
    "logs"
    "backups"
)

###############################################################################
# Required Repository Files
###############################################################################

readonly REQUIRED_REPOSITORY_FILES=(
    "package.json"
    "readme.md"
    "LICENSE"
)

###############################################################################
# Required Repository Directories
###############################################################################

readonly REQUIRED_REPOSITORY_DIRECTORIES=(
    "api"
    "src"
    "themes"
)

###############################################################################
# Minimum Supported Versions
###############################################################################

readonly MINIMUM_BASH_VERSION="5.0"
readonly MINIMUM_GIT_VERSION="2.40.0"
readonly MINIMUM_DOCKER_VERSION="28.0.0"
readonly MINIMUM_DOCKER_COMPOSE_VERSION="2.0.0"

###############################################################################
# Retry Configuration
###############################################################################

readonly RETRY_COUNT=3
readonly RETRY_DELAY=2

###############################################################################
# Network Configuration
###############################################################################

readonly GITHUB_CHECK_URL="${UPSTREAM_REPOSITORY}"

###############################################################################
# Backup Configuration
###############################################################################

readonly BACKUP_RETENTION_COUNT=5

###############################################################################
# Default Runtime Values
#
# Used as fallback values if not explicitly provided during configuration.
###############################################################################

readonly DEFAULT_PORT="9000"
readonly DEFAULT_HTTP_PORT="80"
readonly DEFAULT_CACHE_SECONDS="21600"
readonly DEFAULT_LOG_LEVEL="INFO"

###############################################################################
# End of File
###############################################################################