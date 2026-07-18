#!/usr/bin/env bash
# shellcheck shell=bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Configuration Script
#
# Responsibilities
#   - Create required directories
#   - Create .env from .env.example
#   - Load environment variables
#
# This script does NOT:
#   - Validate configuration values
#   - Clone repositories
#   - Deploy the application
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

###############################################################################
# Script Directory
###############################################################################

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

###############################################################################
# Load Libraries
###############################################################################

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Helper Functions
###############################################################################

is_positive_integer() {

    [[ "$1" =~ ^[0-9]+$ ]]

}

###############################################################################
# Workspace Setup
###############################################################################

create_required_directories() {

    print_section "Creating Required Directories"

    local directories=(
        "${DEPLOYMENT_DIRECTORY}"
        "${BACKUP_DIRECTORY}"
        "${LOG_DIRECTORY}"
        "${DOCKER_DIRECTORY}"
        "${COMPOSE_DIRECTORY}"
    )

    local directory

    for directory in "${directories[@]}"; do
        ensure_directory "${directory}"
    done

    log_success "Directory structure is ready."

}

create_env_file() {

    print_section "Preparing Environment File"

    if [[ -f "${ENV_FILE}" ]]; then

        log_info ".env already exists."

        return

    fi

    if [[ ! -f "${ENV_EXAMPLE_FILE}" ]]; then
        die ".env.example not found."
    fi

    copy_if_missing "${ENV_EXAMPLE_FILE}" "${ENV_FILE}"

    log_success ".env created from .env.example."

}

load_environment() {

    print_section "Loading Environment"

    if ! load_env "${ENV_FILE}"; then
        die "Failed to load environment variables."
    fi

    log_success "Environment variables loaded."

}

###############################################################################
# Configuration Validation
###############################################################################

validate_required_keys() {

    print_section "Validating Required Configuration Keys"

    local key

    for key in "${REQUIRED_ENV_KEYS[@]}"; do

        if [[ -z "${!key+x}" ]]; then
            die "Missing required configuration key: ${key}"
        fi

    done

    log_success "All required configuration keys are present."

}

validate_pat() {

    if [[ -z "${PAT_1}" ]]; then
        die "PAT_1 must not be empty."
    fi

}

validate_port() {

    if ! is_positive_integer "${PORT}"; then
        die "PORT must be a positive integer."
    fi

    if (( PORT < 1 || PORT > 65535 )); then
        die "PORT must be between 1 and 65535."
    fi

}

validate_cache_seconds() {

    if ! is_positive_integer "${CACHE_SECONDS}"; then
        die "CACHE_SECONDS must be a positive integer."
    fi

}

validate_environment() {

    case "${ENVIRONMENT}" in

        development|production)
            ;;

        *)
            die "ENVIRONMENT must be either 'development' or 'production'."
            ;;

    esac

}

validate_log_level() {

    case "${LOG_LEVEL}" in

        DEBUG|INFO|WARNING|ERROR)
            ;;

        *)
            die "LOG_LEVEL must be one of: DEBUG, INFO, WARNING or ERROR."
            ;;

    esac

}

validate_configuration_values() {

    print_section "Validating Configuration Values"

    validate_pat

    validate_port

    validate_cache_seconds

    validate_environment

    validate_log_level

    log_success "Configuration values are valid."

}

###############################################################################
# Reporting
###############################################################################

print_configuration_summary() {

    print_header "Configuration Summary"

    printf "Project Root      : %s\n" "${PROJECT_ROOT}"
    printf "Environment File  : %s\n" "${ENV_FILE}"
    printf "Deployment Dir    : %s\n" "${DEPLOYMENT_DIRECTORY}"
    printf "Backup Dir        : %s\n" "${BACKUP_DIRECTORY}"
    printf "Log Dir           : %s\n" "${LOG_DIRECTORY}"

    printf "\nEnvironment\n\n"

    if [[ -n "${PAT_1}" ]]; then
        printf "PAT_1             : Configured\n"
    else
        printf "PAT_1             : Missing\n"
    fi

    printf "PORT              : %s\n" "${PORT}"
    printf "CACHE_SECONDS     : %s\n" "${CACHE_SECONDS}"
    printf "ENVIRONMENT       : %s\n" "${ENVIRONMENT}"
    printf "LOG_LEVEL         : %s\n" "${LOG_LEVEL}"

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "Configure"

    create_required_directories

    create_env_file

    load_environment

    validate_required_keys

    validate_configuration_values

    print_configuration_summary

    log_success "Workspace configuration completed successfully."

}

main "$@"