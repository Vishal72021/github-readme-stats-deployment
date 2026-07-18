#!/usr/bin/env sh

###############################################################################
# Container Health Check
#
# Verifies that the GitHub Readme Stats application is responding from inside
# the running container.
#
# Responsibilities
#   - Build the local application health-check URL
#   - Perform an HTTP health request
#   - Return a Docker-compatible exit status
#
# Exit Codes
#   0 - Application is healthy
#   1 - Application is unhealthy
###############################################################################

set -eu

###############################################################################
# Health Check Configuration
###############################################################################

HEALTH_CHECK_HOST="${HEALTH_CHECK_HOST:-127.0.0.1}"
HEALTH_CHECK_PORT="${PORT:-9000}"
HEALTH_CHECK_PATH="${HEALTH_CHECK_PATH:-/api/}"

###############################################################################
# Health Check
###############################################################################

check_application_health() {

    local health_url

    health_url="http://${HEALTH_CHECK_HOST}:${HEALTH_CHECK_PORT}${HEALTH_CHECK_PATH}"

    if curl \
        --silent \
        --show-error \
        --output /dev/null \
        --max-time 5 \
        "${health_url}"; then

        exit 0

    fi

    exit 1

}

###############################################################################
# Main
###############################################################################

main() {

    check_application_health

}

main "$@"