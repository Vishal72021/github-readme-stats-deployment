#!/usr/bin/env bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Certbot Post-Renewal Hook
#
# Responsibilities
#   - Run after Certbot completes a certificate renewal attempt
#   - Verify the Docker runtime is available
#   - Verify the deployment configuration exists
#   - Start the Nginx reverse proxy container
#   - Restore HTTP and HTTPS traffic after certificate renewal
#
# This file intentionally does NOT:
#   - Start or restart the application container
#   - Renew certificates directly
#   - Modify firewall rules
#   - Modify TLS certificate files
#
# Installation target
#   /etc/letsencrypt/renewal-hooks/post/
#
# Notes
#   - The Nginx container mounts Let's Encrypt certificates read-only.
#   - Starting the container causes Nginx to load the current certificate files.
#   - This hook runs after Certbot finishes the renewal attempt.
###############################################################################

set -Eeuo pipefail

###############################################################################
# Configuration
###############################################################################

readonly PROJECT_ROOT="/home/ubuntu/github-readme-stats-deployment"

readonly ENV_FILE="${PROJECT_ROOT}/.env"

readonly COMPOSE_FILE="${PROJECT_ROOT}/compose/docker-compose.yml"

readonly NGINX_SERVICE="nginx"

###############################################################################
# Logging
###############################################################################

log() {

    local level="$1"

    shift

    printf "[%s] %-7s %s\n" \
        "$(date -u '+%Y-%m-%d %H:%M:%S UTC')" \
        "${level}" \
        "$*"

}

log_info() {

    log "INFO" "$@"

}

log_success() {

    log "SUCCESS" "$@"

}

log_error() {

    log "ERROR" "$@" >&2

}

###############################################################################
# Error Handling
###############################################################################

handle_error() {

    local exit_code=$?

    log_error \
        "Certbot post-renewal hook failed with exit code ${exit_code}."

    exit "${exit_code}"

}

trap handle_error ERR

###############################################################################
# Validation
###############################################################################

validate_environment() {

    if ! command -v docker > /dev/null 2>&1; then

        log_error "Docker command is not available."

        return 1

    fi

    if ! docker compose version > /dev/null 2>&1; then

        log_error "Docker Compose is not available."

        return 1

    fi

    if [[ ! -f "${ENV_FILE}" ]]; then

        log_error "Environment file not found: ${ENV_FILE}"

        return 1

    fi

    if [[ ! -f "${COMPOSE_FILE}" ]]; then

        log_error "Docker Compose file not found: ${COMPOSE_FILE}"

        return 1

    fi

}

###############################################################################
# Nginx Startup
###############################################################################

start_nginx() {

    log_info \
        "Starting Nginx service '${NGINX_SERVICE}' after certificate renewal."

    docker compose \
        --env-file "${ENV_FILE}" \
        -f "${COMPOSE_FILE}" \
        start "${NGINX_SERVICE}"

    log_success \
        "Nginx service started. HTTP and HTTPS traffic restored."

}

###############################################################################
# Main
###############################################################################

main() {

    log_info "Starting Certbot post-renewal hook."

    validate_environment

    start_nginx

    log_success "Certbot post-renewal hook completed successfully."

}

main "$@"