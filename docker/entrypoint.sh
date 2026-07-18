#!/usr/bin/env sh

###############################################################################
# Container Entrypoint
#
# Initializes the GitHub Readme Stats application container before handing
# control to the application process.
#
# Responsibilities
#   - Validate required runtime configuration
#   - Report safe runtime information
#   - Execute the container command
#
# This script does NOT:
#   - Print or expose secrets
#   - Install dependencies
#   - Modify application source
#   - Perform deployment orchestration
###############################################################################

set -eu

###############################################################################
# Logging
###############################################################################

log_info() {

    printf "[ENTRYPOINT] [INFO] %s\n" "$*"

}

log_error() {

    printf "[ENTRYPOINT] [ERROR] %s\n" "$*" >&2

}

###############################################################################
# Runtime Configuration Validation
###############################################################################

validate_runtime_configuration() {

    log_info "Validating runtime configuration..."

    if [ -z "${PAT_1:-}" ]; then
        log_error "Required environment variable 'PAT_1' is not configured."
        exit 1
    fi

    if [ -z "${PORT:-}" ]; then
        log_error "Required environment variable 'PORT' is not configured."
        exit 1
    fi

    log_info "Runtime configuration is valid."

}

###############################################################################
# Runtime Summary
###############################################################################

print_runtime_summary() {

    log_info "Starting GitHub Readme Stats."
    log_info "Environment: ${ENVIRONMENT:-production}"
    log_info "Port: ${PORT}"
    log_info "GitHub PAT: Configured"

}

###############################################################################
# Application Startup
###############################################################################

start_application() {

    if [ "$#" -eq 0 ]; then
        log_error "No application command was provided."
        exit 1
    fi

    log_info "Executing application command."

    exec "$@"

}

###############################################################################
# Main
###############################################################################

main() {

    validate_runtime_configuration

    print_runtime_summary

    start_application "$@"

}

main "$@"