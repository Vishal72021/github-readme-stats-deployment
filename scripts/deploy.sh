#!/usr/bin/env bash

###############################################################################
# Deployment
#
# Deploys the GitHub Readme Stats application into the configured Docker
# environment.
#
# Responsibilities
#   - Verify the deployment workspace
#   - Validate deployment secrets
#   - Verify the Docker runtime
#   - Prepare deployment resources
#   - Deploy the application
#   - Verify container health
#   - Verify application health
#   - Report deployment status
#
# This script does NOT:
#   - Bootstrap the workspace
#   - Clone the upstream repository
#   - Update the upstream repository
#   - Create backups
#   - Restore backups
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

###############################################################################
# Load Libraries
###############################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Deployment Verification
###############################################################################

verify_workspace() {

    print_section "Verifying Deployment Workspace"

    if [[ ! -f "${ENV_FILE}" ]]; then
        die \
            "Environment file not found at '${ENV_FILE}'. " \
            "Run 'bash scripts/bootstrap.sh' first."
    fi

    if [[ ! -d "${REPOSITORY_DIRECTORY}/.git" ]]; then
        die \
            "Repository not found at '${REPOSITORY_DIRECTORY}'. " \
            "Run 'bash scripts/bootstrap.sh' first."
    fi

    local file

    for file in "${REQUIRED_REPOSITORY_FILES[@]}"; do

        if [[ ! -f "${REPOSITORY_DIRECTORY}/${file}" ]]; then
            die "Required repository file '${file}' not found."
        fi

    done

    local directory

    for directory in "${REQUIRED_REPOSITORY_DIRECTORIES[@]}"; do

        if [[ ! -d "${REPOSITORY_DIRECTORY}/${directory}" ]]; then
            die "Required repository directory '${directory}' not found."
        fi

    done

    log_success "Deployment workspace verified."

}

validate_deployment_secrets() {

    print_section "Validating Deployment Secrets"

    if ! load_env "${ENV_FILE}"; then
        die "Unable to load environment file '${ENV_FILE}'."
    fi

    local secret

    for secret in "${REQUIRED_DEPLOYMENT_SECRETS[@]}"; do

        if [[ -z "${!secret:-}" ]]; then
            die \
                "Required deployment secret '${secret}' is not configured. " \
                "Update '${ENV_FILE}' before deployment."
        fi

    done

    log_success "Required deployment secrets are configured."

}

verify_docker_runtime() {

    print_section "Verifying Docker Runtime"

    if ! command_exists docker; then
        die "Docker is not installed or is not available in PATH."
    fi

    if ! retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        docker info >/dev/null 2>&1; then

        die \
            "Docker daemon is unavailable. " \
            "Ensure Docker Desktop is running and WSL integration is enabled."
    fi

    if ! docker compose version >/dev/null 2>&1; then
        die "Docker Compose is unavailable."
    fi

    log_success "Docker runtime is available."

}

###############################################################################
# Deployment
###############################################################################

prepare_deployment() {

    print_section "Preparing Deployment"

    if [[ ! -f "${DOCKERFILE}" ]]; then
        die "Dockerfile not found at '${DOCKERFILE}'."
    fi

    if [[ ! -f "${DOCKER_ENTRYPOINT}" ]]; then
        die "Docker entrypoint not found at '${DOCKER_ENTRYPOINT}'."
    fi

    if [[ ! -f "${DOCKER_HEALTHCHECK}" ]]; then
        die "Docker health check not found at '${DOCKER_HEALTHCHECK}'."
    fi

    if [[ ! -f "${COMPOSE_FILE}" ]]; then
        die "Docker Compose file not found at '${COMPOSE_FILE}'."
    fi

    log_info "Validating Docker Compose configuration..."

    if ! docker compose \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        config \
        --quiet; then

        die "Docker Compose configuration is invalid."
    fi

    log_info "Building application image..."

    if ! retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        docker compose \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        build \
        "${DOCKER_SERVICE_NAME}"; then

        die "Failed to build application image."
    fi

    log_success "Deployment resources prepared successfully."

}

deploy_application() {

    print_section "Deploying Application"

    log_info "Starting application service..."

    if ! retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        docker compose \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        up \
        --detach \
        --no-build \
        "${DOCKER_SERVICE_NAME}"; then

        die "Failed to start application service."
    fi

    log_success "Application service started."

}

###############################################################################
# Health Checks
###############################################################################

verify_containers() {

    print_section "Verifying Containers"

    local container_status

    container_status="$(
        docker inspect \
            --format '{{.State.Status}}' \
            "${DOCKER_CONTAINER_NAME}" \
            2>/dev/null || true
    )"

    if [[ "${container_status}" != "running" ]]; then

        log_error \
            "Container '${DOCKER_CONTAINER_NAME}' is not running. " \
            "Current status: '${container_status:-unknown}'."

        log_info "Displaying recent container logs..."

        docker compose \
            --env-file "${ENV_FILE}" \
            --file "${COMPOSE_FILE}" \
            logs \
            --tail 50 \
            "${DOCKER_SERVICE_NAME}" \
            || true

        die "Container verification failed."
    fi

    log_success \
        "Container '${DOCKER_CONTAINER_NAME}' is running."

}

###############################################################################
# Container Health Verification
###############################################################################

wait_for_container_health() {

    print_section "Waiting for Container Health"

    local health_status
    local attempt=1

    while (( attempt <= CONTAINER_HEALTH_RETRIES )); do

        health_status="$(
            docker inspect \
                --format \
                '{{if .State.Health}}{{.State.Health.Status}}{{else}}unavailable{{end}}' \
                "${DOCKER_CONTAINER_NAME}" \
                2>/dev/null || printf "unknown"
        )"

        case "${health_status}" in

            healthy)

                log_success \
                    "Container '${DOCKER_CONTAINER_NAME}' is healthy."

                return 0

                ;;

            unhealthy)

                log_error \
                    "Container '${DOCKER_CONTAINER_NAME}' is unhealthy."

                log_info "Displaying recent container logs..."

                docker compose \
                    --env-file "${ENV_FILE}" \
                    --file "${COMPOSE_FILE}" \
                    logs \
                    --tail 50 \
                    "${DOCKER_SERVICE_NAME}" \
                    || true

                die "Container health verification failed."

                ;;

            starting)

                if (( attempt < CONTAINER_HEALTH_RETRIES )); then

                    log_info \
                        "Container health status is 'starting'. " \
                        "Waiting ${CONTAINER_HEALTH_DELAY}s..."

                    sleep "${CONTAINER_HEALTH_DELAY}"
                fi

                ;;

            *)

                die \
                    "Unable to determine container health status. " \
                    "Current status: '${health_status}'."

                ;;

        esac

        ((attempt++))

    done

    log_error \
        "Container did not become healthy after " \
        "${CONTAINER_HEALTH_RETRIES} attempts."

    docker compose \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        logs \
        --tail 50 \
        "${DOCKER_SERVICE_NAME}" \
        || true

    die "Container health verification timed out."

}

verify_application() {

    print_section "Verifying Application Health"

    if ! command_exists curl; then
        die "curl is required for application health verification."
    fi

    local health_url
    local attempt=1

    health_url="http://localhost:${PORT}${HEALTH_CHECK_PATH}"

    while (( attempt <= HEALTH_CHECK_RETRIES )); do

        if curl \
            --silent \
            --show-error \
            --output /dev/null \
            --max-time 5 \
            "${health_url}"; then

            log_success "Application health check passed."

            return 0
        fi

        if (( attempt < HEALTH_CHECK_RETRIES )); then

            log_warn \
                "Health check attempt ${attempt}/${HEALTH_CHECK_RETRIES} " \
                "failed. Retrying in ${HEALTH_CHECK_DELAY}s..."

            sleep "${HEALTH_CHECK_DELAY}"
        fi

        ((attempt++))

    done

    log_error \
        "Application health check failed after " \
        "${HEALTH_CHECK_RETRIES} attempts."

    log_info "Displaying recent container logs..."

    docker compose \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        logs \
        --tail 50 \
        "${DOCKER_SERVICE_NAME}" \
        || true

    die "Application health verification failed."

}

###############################################################################
# Reporting
###############################################################################

print_deployment_summary() {

    local container_status
    local container_health
    local application_url

    container_status="$(
        docker inspect \
            --format '{{.State.Status}}' \
            "${DOCKER_CONTAINER_NAME}" \
            2>/dev/null || printf "unknown"
    )"

    container_health="$(
        docker inspect \
            --format \
            '{{if .State.Health}}{{.State.Health.Status}}{{else}}unavailable{{end}}' \
            "${DOCKER_CONTAINER_NAME}" \
            2>/dev/null || printf "unknown"
    )"

    application_url="http://localhost:${PORT}"

    print_separator

    printf "Deployment Summary\n"

    print_separator

    printf "%-20s : %s\n" "Environment" "${ENVIRONMENT:-unknown}"
    printf "%-20s : %s\n" "Repository" "${REPOSITORY_NAME}"
    printf "%-20s : %s\n" "Service" "${DOCKER_SERVICE_NAME}"
    printf "%-20s : %s\n" "Container" "${DOCKER_CONTAINER_NAME}"
    printf "%-20s : %s\n" "Container Status" "${container_status}"
    printf "%-20s : %s\n" "Container Health" "${container_health}"
    printf "%-20s : %s\n" "Application Health" "reachable"
    printf "%-20s : %s\n" "Application Port" "${PORT}"
    printf "%-20s : %s\n" "Application URL" "${application_url}"

    print_separator

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "Deploy"

    verify_workspace

    validate_deployment_secrets

    verify_docker_runtime

    prepare_deployment

    deploy_application

    verify_containers

    wait_for_container_health

    verify_application

    print_deployment_summary

    log_success "Application deployment completed successfully."

}

main "$@"

###############################################################################
# End of File
###############################################################################