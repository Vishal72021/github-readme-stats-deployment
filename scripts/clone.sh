#!/usr/bin/env bash
# shellcheck shell=bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Repository Clone Script
#
# Responsibilities
#   - Clone the upstream repository if it does not exist.
#
# This script does NOT:
#   - Update repositories
#   - Deploy containers
#   - Build images
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

run_git() {

    [[ -d "${REPOSITORY_DIRECTORY}/.git" ]] || \
        die "Repository not found. Run clone_repository() first."

    git -C "${REPOSITORY_DIRECTORY}" "$@"

}

###############################################################################
# Repository Management
###############################################################################

clone_repository() {

    print_section "Repository Setup"

    if [[ -d "${REPOSITORY_DIRECTORY}/.git" ]]; then

        log_info "Repository already exists."

        return

    fi

    if [[ -e "${REPOSITORY_DIRECTORY}" ]]; then
        die "Repository directory exists but is not a Git repository."
    fi

    log_info "Cloning repository..."

    retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        git clone \
        --branch "${UPSTREAM_BRANCH}" \
        "${UPSTREAM_REPOSITORY}" \
        "${REPOSITORY_DIRECTORY}"

    log_success "Repository cloned successfully."

}

###############################################################################
# Repository Validation
###############################################################################

verify_repository() {

    print_section "Verifying Repository"

    if [[ ! -d "${REPOSITORY_DIRECTORY}/.git" ]]; then
        die "Repository directory exists but is not a Git repository."
    fi

    run_git fsck --no-progress

    log_success "Repository is valid."

}

verify_remote() {

    print_section "Verifying Remote"

    local remote_url

    remote_url="$(run_git remote get-url origin)"

    if [[ "${remote_url}" != "${UPSTREAM_REPOSITORY}" ]]; then

        die "Repository remote does not match '${UPSTREAM_REPOSITORY}'."

    fi

    log_success "Remote configuration verified."

}

fetch_repository() {

    print_section "Fetching Repository"

    retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        run_git fetch "${UPSTREAM_REMOTE}"

    log_success "Repository fetched successfully."

}

checkout_branch() {

    print_section "Checking Out Branch"

    if run_git show-ref --verify --quiet \
        "refs/heads/${UPSTREAM_BRANCH}"; then

        run_git checkout "${UPSTREAM_BRANCH}" >/dev/null

    else

        run_git checkout \
            -b "${UPSTREAM_BRANCH}" \
            --track "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"

    fi

    log_success "Checked out '${UPSTREAM_BRANCH}'."

}

update_repository() {

    print_section "Updating Repository"

    retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        run_git pull \
        --ff-only \
        "${UPSTREAM_REMOTE}" \
        "${UPSTREAM_BRANCH}" >/dev/null

    log_success "Repository is up to date."

}

###############################################################################
# Reporting
###############################################################################

print_repository_summary() {

    print_section "Repository Summary"

    local current_branch
    local current_commit
    local remote_url

    current_branch="$(run_git branch --show-current)"
    current_commit="$(run_git rev-parse --short HEAD)"
    remote_url="$(run_git remote get-url "${UPSTREAM_REMOTE}")"
    current_message="$(run_git log -1 --pretty=%s)"

    printf "%-20s %s\n" "Repository:" "${REPOSITORY_NAME}"
    printf "%-20s %s\n" "Directory:" "${REPOSITORY_DIRECTORY}"
    printf "%-20s %s\n" "Remote:" "${remote_url}"
    printf "%-20s %s\n" "Branch:" "${current_branch}"
    printf "%-20s %s\n" "Commit:" "${current_commit}"
    printf "%-20s %s\n" "Message:" "${current_message}"

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "Clone"

    clone_repository

    verify_repository

    verify_remote

    fetch_repository

    checkout_branch

    update_repository

    print_repository_summary

    log_success "Repository setup completed successfully."

}

main "$@"