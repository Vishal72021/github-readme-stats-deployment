#!/usr/bin/env bash

###############################################################################
# Environment Validation
#
# Validates that the host system satisfies all prerequisites required for
# deploying GitHub Readme Stats.
#
# Responsibilities
#   - Validate required software
#   - Validate minimum supported versions
#   - Validate network connectivity
#   - Validate configuration files
#
# This script NEVER modifies the system.
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
# Validation Counters
###############################################################################

PASS_COUNT=0
WARN_COUNT=0
FAIL_COUNT=0

###############################################################################
# Result Helpers
###############################################################################

record_pass() {
    PASS_COUNT=$((PASS_COUNT + 1))
}

record_warn() {
    WARN_COUNT=$((WARN_COUNT + 1))
}

record_fail() {
    FAIL_COUNT=$((FAIL_COUNT + 1))
}

###############################################################################
# Validation Wrapper
###############################################################################

run_validation() {

    local title="$1"
    shift

    print_section "${title}"

    "$@"

}

###############################################################################
# Bash Validation
###############################################################################

validate_bash() {

    if ! command_exists bash; then
        log_error "Bash is not installed."
        record_fail
        return
    fi

    local version

    version="$(bash --version | head -n1 | awk '{print $4}')"

    if version_ge "${version}" "${MINIMUM_BASH_VERSION}"; then
        log_success "Bash ${version}"
        record_pass
    else
        log_error \
            "Bash ${version} detected. Minimum required: ${MINIMUM_BASH_VERSION}"
        record_fail
    fi

}

###############################################################################
# Git Validation
###############################################################################

validate_git() {

    if ! command_exists git; then
        log_error "Git is not installed."
        record_fail
        return
    fi

    local version

    version="$(git --version | awk '{print $3}')"

    if version_ge "${version}" "${MINIMUM_GIT_VERSION}"; then
        log_success "Git ${version}"
        record_pass
    else
        log_error \
            "Git ${version} detected. Minimum required: ${MINIMUM_GIT_VERSION}"
        record_fail
    fi

}

###############################################################################
# Docker Validation
###############################################################################

validate_docker() {

    if ! command_exists docker; then
        log_error "Docker is not installed."
        record_fail
        return
    fi

    if ! retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        docker version >/dev/null 2>&1; then

        log_error "Docker daemon is unavailable."
        record_fail
        return

    fi

    local version

    version="$(
        docker version \
            --format '{{.Server.Version}}' \
            2>/dev/null
    )"

    if [[ -z "${version}" ]]; then

        version="$(
            docker --version |
            awk '{print $3}' |
            tr -d ','
        )"

    fi

    if version_ge "${version}" "${MINIMUM_DOCKER_VERSION}"; then

        log_success "Docker ${version}"
        record_pass

    else

        log_error \
            "Docker ${version} detected. Minimum required: ${MINIMUM_DOCKER_VERSION}"

        record_fail

    fi

}

###############################################################################
# Docker Compose Validation
###############################################################################

validate_docker_compose() {

    if ! command_exists docker; then
        log_error "Docker is not installed."
        record_fail
        return
    fi

    if ! retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        docker compose version >/dev/null 2>&1; then

        log_error "Docker Compose is unavailable."
        record_fail
        return

    fi

    local version

    version="$(docker compose version --short 2>/dev/null || true)"

    if [[ -z "${version}" ]]; then
        version="$(
            docker compose version |
            awk '{print $4}' |
            sed 's/^v//'
        )"
    fi

    if version_ge "${version}" "${MINIMUM_DOCKER_COMPOSE_VERSION}"; then
        log_success "Docker Compose ${version}"
        record_pass
    else
        log_error \
            "Docker Compose ${version} detected. Minimum required: ${MINIMUM_DOCKER_COMPOSE_VERSION}"
        record_fail
    fi

}

###############################################################################
# Network Validation
###############################################################################

validate_network() {

    if retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        git ls-remote "${GITHUB_CHECK_URL}" >/dev/null 2>&1; then

        log_success "GitHub is reachable."
        record_pass

    else

        log_error "Unable to reach GitHub."
        record_fail

    fi

}

###############################################################################
# Environment Validation Helpers
###############################################################################

validate_env_keys() {

    local file="$1"

    local valid=true

    for key in "${REQUIRED_ENV_KEYS[@]}"; do

        if grep -q "^${key}=" "${file}"; then
            continue
        fi

        log_error "Missing key '${key}' in $(basename "${file}")"
        valid=false

    done

    if ${valid}; then
        return 0
    fi

    return 1

}

###############################################################################
# Environment Files Validation
###############################################################################

validate_environment_files() {

    ############################################################
    # .env.example
    ############################################################

    if [[ ! -f "${ENV_EXAMPLE_FILE}" ]]; then
        log_error ".env.example not found."
        record_fail
    else

        if validate_env_keys "${ENV_EXAMPLE_FILE}"; then
            log_success ".env.example is valid."
            record_pass
        else
            record_fail
        fi

    fi

    ############################################################
    # .env
    ############################################################

    if [[ ! -f "${ENV_FILE}" ]]; then

        log_warn ".env not found. It will be created during configuration."
        record_warn
        return

    fi

    if validate_env_keys "${ENV_FILE}"; then
        log_success ".env is valid."
        record_pass
    else
        record_fail
    fi

}

###############################################################################
# Diagnostics
###############################################################################

print_diagnostics() {

    print_separator
    printf "Diagnostics\n"
    print_separator

    printf "Project Root        : %s\n" "${PROJECT_ROOT}"
    printf "Operating System    : %s\n" "$(uname -sr)"

    if command_exists bash; then
        printf "Bash Version        : %s\n" \
            "$(bash --version | head -n1)"
    fi

    if command_exists git; then
        printf "Git Version         : %s\n" \
            "$(git --version)"
    fi

    if command_exists docker; then

        if docker version >/dev/null 2>&1; then
            printf "Docker Version      : %s\n" \
                "$(docker --version)"

            printf "Compose Version     : %s\n" \
                "$(docker compose version)"
        fi

    fi

}

###############################################################################
# Summary
###############################################################################

print_summary() {

    print_separator
    printf "Validation Summary\n"
    print_separator

    printf "Checks Passed : %d\n" "${PASS_COUNT}"
    printf "Warnings      : %d\n" "${WARN_COUNT}"
    printf "Failures      : %d\n" "${FAIL_COUNT}"

    print_separator

    if (( FAIL_COUNT == 0 )); then
        log_success "Environment validation completed successfully."
    else
        log_error "Environment validation failed."
    fi

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "Validate"

    run_validation "Checking Bash" validate_bash

    run_validation "Checking Git" validate_git

    run_validation "Checking Docker" validate_docker

    run_validation "Checking Docker Compose" \
        validate_docker_compose

    run_validation "Checking Network Connectivity" \
        validate_network

    run_validation "Checking Environment Files" \
        validate_environment_files

    print_diagnostics

    print_summary

    if (( FAIL_COUNT > 0 )); then
        exit "${EXIT_FAILURE}"
    fi

    exit "${EXIT_SUCCESS}"

}

main "$@"