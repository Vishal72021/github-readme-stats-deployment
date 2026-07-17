#!/usr/bin/env bash
# shellcheck shell=bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Bootstrap Script
#
# Responsibilities
#   - Execute the deployment prerequisites.
#   - Prepare a deployment-ready workspace.
#
# This script does NOT:
#   - Deploy containers
#   - Update repositories
#   - Create backups
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
# Script Helpers
###############################################################################

run_script() {

    local script_name="$1"

    bash "${SCRIPT_DIR}/${script_name}"

}

###############################################################################
# Bootstrap Helpers
###############################################################################

run_validation() {

    print_section "Running Validation"

    run_script "validate.sh"

    log_success "Validation completed."

}

run_configuration() {

    print_section "Running Configuration"

    run_script "configure.sh"

    log_success "Configuration completed."

}

load_bootstrap_environment() {

    print_section "Loading Bootstrap Environment"

    load_env "${ENV_FILE}" || \
        die "Failed to load '${ENV_FILE}'."

    log_success "Bootstrap environment loaded."

}

run_clone() {

    print_section "Running Repository Clone"

    run_script "clone.sh"

    log_success "Repository setup completed."

}

###############################################################################
# Deployment Verification
###############################################################################

verify_deployment_files() {

    print_section "Verifying Deployment Files"

    local file

    for file in "${REQUIRED_DEPLOYMENT_FILES[@]}"; do

        if [[ ! -f "${PROJECT_ROOT}/${file}" ]]; then
            die "Required deployment file '${file}' not found."
        fi

    done

    log_success "Required deployment files verified."

}

verify_deployment_directories() {

    print_section "Verifying Deployment Directories"

    local directory

    for directory in "${REQUIRED_DEPLOYMENT_DIRECTORIES[@]}"; do

        if [[ ! -d "${PROJECT_ROOT}/${directory}" ]]; then
            die "Required deployment directory '${directory}' not found."
        fi

    done

    log_success "Required deployment directories verified."

}

###############################################################################
# Workspace Verification
###############################################################################

verify_repository_files() {

    print_section "Verifying Repository Files"

    local file

    for file in "${REQUIRED_REPOSITORY_FILES[@]}"; do

        if [[ ! -f "${REPOSITORY_DIRECTORY}/${file}" ]]; then
            die "Required repository file '${file}' not found."
        fi

    done

    log_success "Required repository files verified."

}

verify_repository_directories() {

    print_section "Verifying Repository Directories"

    local directory

    for directory in "${REQUIRED_REPOSITORY_DIRECTORIES[@]}"; do

        if [[ ! -d "${REPOSITORY_DIRECTORY}/${directory}" ]]; then
            die "Required repository directory '${directory}' not found."
        fi

    done

    log_success "Required repository directories verified."

}

verify_bootstrap() {

    print_section "Bootstrap Verification"

    verify_deployment_files

    verify_deployment_directories

    verify_repository_files

    verify_repository_directories

    log_success "Bootstrap verification completed."

}

###############################################################################
# Reporting
###############################################################################

print_environment_summary() {

    print_section "Environment Summary"

    local pat_status="Not Configured"

    if [[ -n "${PAT_1:-}" ]]; then
        pat_status="Configured"
    fi

    printf "%-20s %s\n" "Environment:" "${ENVIRONMENT:-Not Loaded}"
    printf "%-20s %s\n" "Port:" "${PORT:-NA}"
    printf "%-20s %s\n" "Cache Seconds:" "${CACHE_SECONDS:-NA}"
    printf "%-20s %s\n" "Log Level:" "${LOG_LEVEL:-NA}"
    printf "%-20s %s\n" "GitHub PAT:" "${pat_status:-NA}"

}

print_bootstrap_summary() {

    print_section "Bootstrap Summary"

    printf "%-20s %s\n" "Project:" "${PROJECT_NAME}"
    printf "%-20s %s\n" "Version:" "${PROJECT_VERSION}"
    printf "%-20s %s\n" "Project Root:" "${PROJECT_ROOT}"
    printf "%-20s %s\n" "Repository:" "${REPOSITORY_NAME}"
    printf "%-20s %s\n" "Repository Path:" "${REPOSITORY_DIRECTORY}"
    printf "%-20s %s\n" "Branch:" "${UPSTREAM_BRANCH}"
    printf "%-20s %s\n" "Workspace:" "Ready"

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "Bootstrap"

    run_validation

    run_configuration

    load_bootstrap_environment

    run_clone

    verify_bootstrap

    print_environment_summary

    print_bootstrap_summary

    log_success "Bootstrap completed successfully."

}

main "$@"