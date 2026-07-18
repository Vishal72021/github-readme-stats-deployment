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
# Helper Functions
###############################################################################

compose() {

    docker compose \
        --env-file "${ENV_FILE}" \
        --file "${COMPOSE_FILE}" \
        "$@"

}

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

    if ! compose config --quiet; then

        die "Docker Compose configuration is invalid."

    fi

    log_info "Building application image..."

    if ! retry_command \
    "${RETRY_COUNT}" \
    "${RETRY_DELAY}" \
    compose build \
    "${APPLICATION_SERVICE}"; then

        die "Failed to build application image."

    fi

    log_success "Deployment resources prepared successfully."

}

deploy_stack() {

    print_section "Deploying Application Stack"

    log_info "Starting application stack..."

    compose up -d

    log_success "Application stack started."

}

###############################################################################
# Health Checks
###############################################################################

verify_application_container() {

    print_section "Verifying Application Container"

    local status

    status="$(
        docker inspect \
            --format '{{.State.Status}}' \
            "${APPLICATION_CONTAINER}" \
            2>/dev/null
    )" || die \
        "Unable to inspect application container '${APPLICATION_CONTAINER}'."

    if [[ "${status}" != "running" ]]; then
        die \
            "Application container '${APPLICATION_CONTAINER}' " \
            "is not running."
    fi

    log_success \
        "Application container '${APPLICATION_CONTAINER}' is running."

}

verify_proxy_container() {

    print_section "Verifying Proxy Container"

    local status

    status="$(
        docker inspect \
            --format '{{.State.Status}}' \
            "${PROXY_CONTAINER}" \
            2>/dev/null
    )" || die \
        "Unable to inspect proxy container '${PROXY_CONTAINER}'."

    if [[ "${status}" != "running" ]]; then
        die \
            "Proxy container '${PROXY_CONTAINER}' is not running."
    fi

    log_success \
        "Proxy container '${PROXY_CONTAINER}' is running."

}

###############################################################################
# Container Health Verification
###############################################################################

get_container_health() {

    local container_name="$1"

    docker inspect \
        --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' \
        "${container_name}" \
        2>/dev/null

}

verify_application_health() {

    print_section "Verifying Application Health"

    local attempt
    local health_status

    for ((attempt = 1; attempt <= HEALTH_CHECK_RETRIES; attempt++)); do

        health_status="$(
            get_container_health "${APPLICATION_CONTAINER}"
        )" || die \
            "Unable to determine application container health."

        if [[ "${health_status}" == "healthy" ]]; then

            log_success "Application health check passed."

            return 0

        fi

        log_warn \
            "Application health check attempt " \
            "${attempt}/${HEALTH_CHECK_RETRIES} failed. " \
            "Current status: ${health_status}. " \
            "Retrying in ${HEALTH_CHECK_DELAY}s..."

        sleep "${HEALTH_CHECK_DELAY}"

    done

    die \
        "Application failed to become healthy after " \
        "${HEALTH_CHECK_RETRIES} attempts."

}

verify_proxy_health() {

    print_section "Verifying Reverse Proxy Health"

    local attempt
    local health_status

    for ((attempt = 1; attempt <= HEALTH_CHECK_RETRIES; attempt++)); do

        health_status="$(
            get_container_health "${PROXY_CONTAINER}"
        )" || die \
            "Unable to determine reverse proxy container health."

        if [[ "${health_status}" == "healthy" ]]; then

            log_success "Reverse proxy health check passed."

            return 0

        fi

        log_warn \
            "Reverse proxy health check attempt " \
            "${attempt}/${HEALTH_CHECK_RETRIES} failed. " \
            "Current status: ${health_status}. " \
            "Retrying in ${HEALTH_CHECK_DELAY}s..."

        sleep "${HEALTH_CHECK_DELAY}"

    done

    die \
        "Reverse proxy failed to become healthy after " \
        "${HEALTH_CHECK_RETRIES} attempts."

}

verify_proxy_route() {

    print_section "Verifying Reverse Proxy Route"

    local attempt
    local proxy_url

    proxy_url="http://localhost:${HTTP_PORT}/api?username=octocat"

    for ((attempt = 1; attempt <= HEALTH_CHECK_RETRIES; attempt++)); do

        if curl \
            --fail \
            --silent \
            --show-error \
            --output /dev/null \
            --max-time 10 \
            "${proxy_url}"; then

            log_success \
                "End-to-end reverse proxy verification passed."

            return 0

        fi

        log_warn \
            "Reverse proxy verification attempt " \
            "${attempt}/${HEALTH_CHECK_RETRIES} failed. " \
            "Retrying in ${HEALTH_CHECK_DELAY}s..."

        sleep "${HEALTH_CHECK_DELAY}"

    done

    die "End-to-end reverse proxy verification failed."

}

###############################################################################
# Reporting
###############################################################################

print_deployment_summary() {

    local application_status
    local application_health
    local proxy_status
    local proxy_health

    application_status="$(
        docker inspect \
            --format '{{.State.Status}}' \
            "${APPLICATION_CONTAINER}"
    )"

    application_health="$(
        get_container_health "${APPLICATION_CONTAINER}"
    )"

    proxy_status="$(
        docker inspect \
            --format '{{.State.Status}}' \
            "${PROXY_CONTAINER}"
    )"

    proxy_health="$(
        get_container_health "${PROXY_CONTAINER}"
    )"

    print_separator
    printf "Deployment Summary\n"
    print_separator

    printf "%-22s : %s\n" \
        "Environment" "${ENVIRONMENT}"

    printf "%-22s : %s\n" \
        "Repository" "${REPOSITORY_NAME}"

    printf "%-22s : %s\n" \
        "Application Service" "${APPLICATION_SERVICE}"

    printf "%-22s : %s\n" \
        "Application Container" "${APPLICATION_CONTAINER}"

    printf "%-22s : %s\n" \
        "Application Status" "${application_status}"

    printf "%-22s : %s\n" \
        "Application Health" "${application_health}"

    printf "%-22s : %s\n" \
        "Proxy Service" "${PROXY_SERVICE}"

    printf "%-22s : %s\n" \
        "Proxy Container" "${PROXY_CONTAINER}"

    printf "%-22s : %s\n" \
        "Proxy Status" "${proxy_status}"

    printf "%-22s : %s\n" \
        "Proxy Health" "${proxy_health}"

    printf "%-22s : %s\n" \
        "HTTP Port" "${HTTP_PORT}"

    printf "%-22s : http://localhost:%s\n" \
        "Application URL" "${HTTP_PORT}"

    print_separator

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "GitHub Readme Stats Deployment - Deploy"

    printf "Version : %s\n\n" "${PROJECT_VERSION}"

    verify_workspace

    validate_deployment_secrets

    verify_docker_runtime

    prepare_deployment

    deploy_stack

    verify_application_container

    verify_application_health

    verify_proxy_container

    verify_proxy_health

    verify_proxy_route

    print_deployment_summary

    log_success \
        "Application deployment completed successfully."

}

main "$@"

###############################################################################
# End of File
###############################################################################