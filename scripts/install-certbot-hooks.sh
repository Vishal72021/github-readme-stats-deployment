#!/usr/bin/env bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Certbot Renewal Hook Installer
#
# Responsibilities
#   - Validate Certbot and Docker runtime prerequisites
#   - Validate repository Certbot hook source files
#   - Validate deployment configuration files
#   - Create Certbot renewal hook directories when required
#   - Back up existing project-managed Certbot hooks
#   - Install canonical pre-renewal and post-renewal hooks
#   - Apply secure ownership and executable permissions
#   - Validate installed hook syntax
#   - Verify successful installation
#
# This file intentionally does NOT:
#   - Install Certbot
#   - Request or renew TLS certificates
#   - Modify Certbot renewal configuration
#   - Modify firewall rules
#   - Stop or start application containers
#   - Execute the installed renewal hooks
#
# Usage
#   sudo bash scripts/install-certbot-hooks.sh
###############################################################################

set -Eeuo pipefail

###############################################################################
# Script Paths
###############################################################################

readonly SCRIPT_DIRECTORY="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")" > /dev/null 2>&1
    pwd
)"

readonly PROJECT_ROOT="$(
    cd -- "${SCRIPT_DIRECTORY}/.." > /dev/null 2>&1
    pwd
)"

###############################################################################
# Deployment Configuration
###############################################################################

readonly ENV_FILE="${PROJECT_ROOT}/.env"

readonly COMPOSE_FILE="${PROJECT_ROOT}/compose/docker-compose.yml"

###############################################################################
# Source Hooks
###############################################################################

readonly SOURCE_HOOK_DIRECTORY="${SCRIPT_DIRECTORY}/certbot"

readonly SOURCE_PRE_HOOK="${SOURCE_HOOK_DIRECTORY}/pre-renewal.sh"

readonly SOURCE_POST_HOOK="${SOURCE_HOOK_DIRECTORY}/post-renewal.sh"

###############################################################################
# Certbot Installation Paths
###############################################################################

readonly CERTBOT_HOOK_ROOT="/etc/letsencrypt/renewal-hooks"

readonly CERTBOT_PRE_HOOK_DIRECTORY="${CERTBOT_HOOK_ROOT}/pre"

readonly CERTBOT_POST_HOOK_DIRECTORY="${CERTBOT_HOOK_ROOT}/post"

readonly INSTALLED_PRE_HOOK="${CERTBOT_PRE_HOOK_DIRECTORY}/github-readme-stats.sh"

readonly INSTALLED_POST_HOOK="${CERTBOT_POST_HOOK_DIRECTORY}/github-readme-stats.sh"

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

log_warn() {

    log "WARNING" "$@"

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
        "Certbot renewal hook installation failed with exit code ${exit_code}."

    exit "${exit_code}"

}

trap handle_error ERR

###############################################################################
# Privilege Validation
###############################################################################

validate_root() {

    if [[ "${EUID}" -ne 0 ]]; then

        log_error \
            "This installer requires root privileges. " \
            "Run: sudo bash scripts/install-certbot-hooks.sh"

        return 1

    fi

}

###############################################################################
# Runtime Validation
###############################################################################

validate_runtime() {

    if ! command -v certbot > /dev/null 2>&1; then

        log_error "Certbot is not installed or is not available in PATH."

        return 1

    fi

    if ! command -v docker > /dev/null 2>&1; then

        log_error "Docker is not installed or is not available in PATH."

        return 1

    fi

    if ! docker compose version > /dev/null 2>&1; then

        log_error "Docker Compose is not available."

        return 1

    fi

}

###############################################################################
# Deployment Validation
###############################################################################

validate_deployment() {

    if [[ ! -f "${ENV_FILE}" ]]; then

        log_error "Deployment environment file not found: ${ENV_FILE}"

        return 1

    fi

    if [[ ! -f "${COMPOSE_FILE}" ]]; then

        log_error "Docker Compose file not found: ${COMPOSE_FILE}"

        return 1

    fi

}

###############################################################################
# Source Hook Validation
###############################################################################

validate_source_hooks() {

    if [[ ! -f "${SOURCE_PRE_HOOK}" ]]; then

        log_error \
            "Certbot pre-renewal hook source not found: ${SOURCE_PRE_HOOK}"

        return 1

    fi

    if [[ ! -f "${SOURCE_POST_HOOK}" ]]; then

        log_error \
            "Certbot post-renewal hook source not found: ${SOURCE_POST_HOOK}"

        return 1

    fi

    if ! bash -n "${SOURCE_PRE_HOOK}"; then

        log_error \
            "Certbot pre-renewal hook contains invalid Bash syntax."

        return 1

    fi

    if ! bash -n "${SOURCE_POST_HOOK}"; then

        log_error \
            "Certbot post-renewal hook contains invalid Bash syntax."

        return 1

    fi

}

###############################################################################
# Directory Preparation
###############################################################################

prepare_hook_directories() {

    log_info "Preparing Certbot renewal hook directories."

    install \
        -d \
        -o root \
        -g root \
        -m 755 \
        "${CERTBOT_PRE_HOOK_DIRECTORY}" \
        "${CERTBOT_POST_HOOK_DIRECTORY}"

    log_success "Certbot renewal hook directories are ready."

}

###############################################################################
# Existing Hook Backup
###############################################################################

backup_existing_hook() {

    local hook_path="$1"

    local timestamp

    if [[ ! -e "${hook_path}" ]]; then

        return 0

    fi

    timestamp="$(date -u '+%Y%m%dT%H%M%SZ')"

    log_warn \
        "Existing hook detected. Creating backup: " \
        "${hook_path}.${timestamp}.backup"

    cp \
        --preserve=mode,ownership,timestamps \
        "${hook_path}" \
        "${hook_path}.${timestamp}.backup"

}

backup_existing_hooks() {

    log_info "Checking for existing project-managed Certbot hooks."

    backup_existing_hook "${INSTALLED_PRE_HOOK}"

    backup_existing_hook "${INSTALLED_POST_HOOK}"

    log_success "Existing Certbot hook backup check completed."

}

###############################################################################
# Hook Installation
###############################################################################

install_hooks() {

    log_info "Installing Certbot pre-renewal hook."

    install \
        -o root \
        -g root \
        -m 755 \
        "${SOURCE_PRE_HOOK}" \
        "${INSTALLED_PRE_HOOK}"

    log_info "Installing Certbot post-renewal hook."

    install \
        -o root \
        -g root \
        -m 755 \
        "${SOURCE_POST_HOOK}" \
        "${INSTALLED_POST_HOOK}"

    log_success "Certbot renewal hooks installed successfully."

}

###############################################################################
# Installed Hook Validation
###############################################################################

validate_installed_hooks() {

    log_info "Validating installed Certbot renewal hooks."

    if [[ ! -x "${INSTALLED_PRE_HOOK}" ]]; then

        log_error \
            "Installed pre-renewal hook is not executable: ${INSTALLED_PRE_HOOK}"

        return 1

    fi

    if [[ ! -x "${INSTALLED_POST_HOOK}" ]]; then

        log_error \
            "Installed post-renewal hook is not executable: ${INSTALLED_POST_HOOK}"

        return 1

    fi

    if ! bash -n "${INSTALLED_PRE_HOOK}"; then

        log_error \
            "Installed pre-renewal hook contains invalid Bash syntax."

        return 1

    fi

    if ! bash -n "${INSTALLED_POST_HOOK}"; then

        log_error \
            "Installed post-renewal hook contains invalid Bash syntax."

        return 1

    fi

    log_success "Installed Certbot renewal hooks are valid."

}

###############################################################################
# Installation Summary
###############################################################################

print_installation_summary() {

    printf "\n"

    printf "%s\n" \
        "--------------------------------------------------------------------------------"

    printf "Certbot Renewal Hook Installation Summary\n"

    printf "%s\n" \
        "--------------------------------------------------------------------------------"

    printf "%-22s : %s\n" \
        "Project Root" "${PROJECT_ROOT}"

    printf "%-22s : %s\n" \
        "Pre-Renewal Hook" "${INSTALLED_PRE_HOOK}"

    printf "%-22s : %s\n" \
        "Post-Renewal Hook" "${INSTALLED_POST_HOOK}"

    printf "%-22s : %s\n" \
        "Owner" "root:root"

    printf "%-22s : %s\n" \
        "Permissions" "755"

    printf "%s\n" \
        "--------------------------------------------------------------------------------"

}

###############################################################################
# Main
###############################################################################

main() {

    log_info "Starting Certbot renewal hook installation."

    validate_root

    validate_runtime

    validate_deployment

    validate_source_hooks

    prepare_hook_directories

    backup_existing_hooks

    install_hooks

    validate_installed_hooks

    print_installation_summary

    log_success \
        "Certbot renewal hook installation completed successfully."

}

main "$@"