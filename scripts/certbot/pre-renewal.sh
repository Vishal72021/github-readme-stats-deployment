#!/usr/bin/env bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Certbot Pre-Renewal Hook
#
# Responsibilities
#   - Run before Certbot attempts certificate renewal
#   - Verify the Docker runtime is available
#   - Verify the deployment configuration exists
#   - Stop the Nginx reverse proxy container
#   - Release TCP port 80 for the Certbot standalone authenticator
#
# This file intentionally does NOT:
#   - Stop the application container
#   - Renew certificates directly
#   - Modify firewall rules
#   - Start the Nginx reverse proxy
#
# Installation target
#   /etc/letsencrypt/renewal-hooks/pre/
#
# Notes
#   - Certbot uses the standalone authenticator for this deployment.
#   - The standalone authenticator requires exclusive access to TCP port 80.
#   - The application container remains running during certificate renewal.
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
        "Certbot pre-renewal hook failed with exit code ${exit_code}."

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
# Nginx Shutdown
###############################################################################

stop_nginx() {

    log_info \
        "Stopping Nginx service '${NGINX_SERVICE}' for certificate renewal."

    docker compose \
        --env-file "${ENV_FILE}" \
        -f "${COMPOSE_FILE}" \
        stop "${NGINX_SERVICE}"

    log_success \
        "Nginx service stopped. TCP port 80 is available for Certbot."

}

###############################################################################
# Main
###############################################################################

main() {

    log_info "Starting Certbot pre-renewal hook."

    validate_environment

    stop_nginx

    log_success "Certbot pre-renewal hook completed successfully."

}

main "$@"