#!/usr/bin/env bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Update Script
#
# Responsibilities
#   - Validate the update workspace
#   - Verify the upstream repository state
#   - Verify update dependencies
#   - Fetch upstream repository changes
#   - Detect whether an update is available
#   - Create a pre-update backup
#   - Apply safe fast-forward updates
#   - Redeploy the updated application
#   - Report update results
#
# This script intentionally does NOT:
#   - Perform destructive Git resets
#   - Discard local repository changes
#   - Force repository updates
#   - Modify deployment secrets
#   - Duplicate backup implementation
#   - Duplicate deployment implementation
###############################################################################

set -Eeuo pipefail

###############################################################################
# Script Paths
###############################################################################

SCRIPT_DIR="$(
    cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1
    pwd
)"

###############################################################################
# Shared Libraries
###############################################################################

# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

# shellcheck source=config.sh
source "${SCRIPT_DIR}/config.sh"

###############################################################################
# Environment
###############################################################################

if [[ -f "${ENV_FILE}" ]]; then
    load_env "${ENV_FILE}" \
        || die "Failed to load environment file '${ENV_FILE}'."
fi

###############################################################################
# Update Runtime State
###############################################################################

###############################################################################
# Update Runtime State
###############################################################################

###############################################################################
# Update Runtime State
###############################################################################

CURRENT_COMMIT=""
UPSTREAM_COMMIT=""
UPDATED_COMMIT=""
COMMITS_BEHIND=0
UPDATE_AVAILABLE=false
BACKUP_CREATED=false
DEPLOYMENT_COMPLETED=false

###############################################################################
# Repository Helpers
###############################################################################

run_git() {

    [[ -d "${REPOSITORY_DIRECTORY}/.git" ]] || \
        die "Repository not found. Run bootstrap.sh first."

    git -C "${REPOSITORY_DIRECTORY}" "$@"

}

###############################################################################
# Workspace Verification
###############################################################################

verify_update_workspace() {

    print_section "Verifying Update Workspace"

    if [[ ! -d "${REPOSITORY_DIRECTORY}" ]]; then

        die \
            "Repository directory not found at " \
            "'${REPOSITORY_DIRECTORY}'. Run bootstrap.sh first."
    fi

    if [[ ! -d "${REPOSITORY_DIRECTORY}/.git" ]]; then
        die "Repository directory exists but is not a Git repository."
    fi

    if ! run_git rev-parse --is-inside-work-tree \
        >/dev/null 2>&1; then

        die "Repository validation failed."
    fi

        if [[ ! -f "${SCRIPT_DIR}/backup.sh" ]]; then
        die "Required backup script '${SCRIPT_DIR}/backup.sh' not found."
    fi

    if [[ ! -f "${SCRIPT_DIR}/deploy.sh" ]]; then
        die "Required deployment script '${SCRIPT_DIR}/deploy.sh' not found."
    fi

    log_success "Update workspace verified."

}

###############################################################################
# Repository Verification
###############################################################################

verify_repository_state() {

    print_section "Verifying Repository State"

    local remote_url
    local current_branch
    local working_tree_status

    remote_url="$(
        run_git remote get-url "${UPSTREAM_REMOTE}" 2>/dev/null
    )" || die \
        "Unable to determine repository remote '${UPSTREAM_REMOTE}'."

    if [[ "${remote_url}" != "${UPSTREAM_REPOSITORY}" ]]; then

        log_error "Repository remote does not match the expected upstream."

        printf "Expected : %s\n" "${UPSTREAM_REPOSITORY}"
        printf "Actual   : %s\n" "${remote_url}"

        die "Repository remote verification failed."
    fi

    current_branch="$(
        run_git branch --show-current
    )"

    if [[ "${current_branch}" != "${UPSTREAM_BRANCH}" ]]; then

        log_error "Repository is not on the expected upstream branch."

        printf "Expected : %s\n" "${UPSTREAM_BRANCH}"
        printf "Actual   : %s\n" "${current_branch:-detached HEAD}"

        die "Repository branch verification failed."
    fi

    working_tree_status="$(
        run_git status --porcelain
    )"

    if [[ -n "${working_tree_status}" ]]; then

        log_error "Repository contains uncommitted changes."

        printf "\n"
        run_git status --short
        printf "\n"

        die \
            "Update aborted to prevent overwriting local repository changes."
    fi

    log_success "Repository state verified."

}

###############################################################################
# Upstream Synchronization
###############################################################################

fetch_upstream() {

    print_section "Fetching Upstream Changes"

    log_info "Fetching '${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}'..."

    if ! retry_command \
        "${RETRY_COUNT}" \
        "${RETRY_DELAY}" \
        run_git fetch \
        "${UPSTREAM_REMOTE}" \
        "${UPSTREAM_BRANCH}"; then

        die "Failed to fetch upstream repository changes."
    fi

    log_success "Upstream repository fetched successfully."

}

###############################################################################
# Update Detection
###############################################################################

detect_update() {

    print_section "Checking for Updates"

    CURRENT_COMMIT="$(
        run_git rev-parse HEAD
    )" || die "Unable to determine current repository commit."

    UPSTREAM_COMMIT="$(
        run_git rev-parse \
        "${UPSTREAM_REMOTE}/${UPSTREAM_BRANCH}"
    )" || die "Unable to determine upstream repository commit."

    if [[ "${CURRENT_COMMIT}" == "${UPSTREAM_COMMIT}" ]]; then

        UPDATE_AVAILABLE=false
        COMMITS_BEHIND=0

        log_success "Repository is already up to date."

        return
    fi

    if ! run_git merge-base \
        --is-ancestor \
        "${CURRENT_COMMIT}" \
        "${UPSTREAM_COMMIT}"; then

        die \
            "Local repository cannot be safely fast-forwarded to the " \
            "upstream branch."
    fi

    COMMITS_BEHIND="$(
        run_git rev-list \
            --count \
            "${CURRENT_COMMIT}..${UPSTREAM_COMMIT}"
    )"

    UPDATE_AVAILABLE=true

    log_info \
        "Update available. Repository is ${COMMITS_BEHIND} " \
        "commit(s) behind upstream."

}

###############################################################################
# Pre-Update Backup
###############################################################################

create_pre_update_backup() {

    print_section "Creating Pre-Update Backup"

    log_info \
        "Creating backup of current repository state before update..."

    if ! bash "${SCRIPT_DIR}/backup.sh"; then

        die \
            "Pre-update backup failed. Repository update has been aborted."
    fi

    BACKUP_CREATED=true

    log_success "Pre-update backup completed successfully."

}

###############################################################################
# Repository Update
###############################################################################

apply_update() {

    print_section "Applying Repository Update"

    if [[ "${UPDATE_AVAILABLE}" != true ]]; then
        die "Repository update requested when no update is available."
    fi

    if [[ "${BACKUP_CREATED}" != true ]]; then
        die "Repository update cannot proceed without a pre-update backup."
    fi

    log_info \
        "Fast-forwarding '${UPSTREAM_BRANCH}' to the verified " \
        "upstream commit..."

    if ! run_git merge \
        --ff-only \
        "${UPSTREAM_COMMIT}"; then

        die \
            "Repository update failed. The pre-update backup remains " \
            "available for recovery."
    fi

    UPDATED_COMMIT="$(
        run_git rev-parse HEAD
    )" || die "Unable to determine updated repository commit."

    if [[ -z "${UPDATED_COMMIT}" ]]; then
        die "Updated repository commit could not be determined."
    fi

    if [[ "${UPDATED_COMMIT}" != "${UPSTREAM_COMMIT}" ]]; then

        log_error \
            "Updated repository commit does not match the expected " \
            "upstream commit."

        printf "Expected : %s\n" "${UPSTREAM_COMMIT}"
        printf "Actual   : %s\n" "${UPDATED_COMMIT}"

        die \
            "Repository update verification failed. The pre-update " \
            "backup remains available for recovery."
    fi

    log_success "Repository updated successfully."

}

###############################################################################
# Deployment
###############################################################################

redeploy_application() {

    print_section "Redeploying Application"

    if [[ -z "${UPDATED_COMMIT}" ]]; then
        die "Updated repository commit is not available."
    fi

    if [[ "${UPDATED_COMMIT}" != "${UPSTREAM_COMMIT}" ]]; then
        die \
            "Updated repository state is not verified. " \
            "Deployment has been aborted."
    fi

    log_info "Deploying updated application..."

    if ! bash "${SCRIPT_DIR}/deploy.sh"; then

        log_error "Updated application deployment failed."

        die \
            "Repository update completed, but application deployment " \
            "failed. The pre-update backup remains available for recovery."
    fi

    DEPLOYMENT_COMPLETED=true

    log_success "Updated application deployed successfully."

}

###############################################################################
# Reporting
###############################################################################

print_update_summary() {

    local current_short
    local upstream_short
    local updated_short

    current_short="$(
        printf "%.7s" "${CURRENT_COMMIT}"
    )"

    upstream_short="$(
        printf "%.7s" "${UPSTREAM_COMMIT}"
    )"

    updated_short="$(
        printf "%.7s" "${UPDATED_COMMIT}"
    )"

    print_separator

    printf "Update Summary\n"

    print_separator

    printf "%-22s : %s\n" \
        "Repository" \
        "${REPOSITORY_NAME}"

    printf "%-22s : %s\n" \
        "Branch" \
        "${UPSTREAM_BRANCH}"

    printf "%-22s : %s\n" \
        "Previous Commit" \
        "${current_short}"

    printf "%-22s : %s\n" \
        "Upstream Commit" \
        "${upstream_short}"

    printf "%-22s : %s\n" \
        "Updated Commit" \
        "${updated_short}"

    printf "%-22s : %s\n" \
        "Commits Applied" \
        "${COMMITS_BEHIND}"

    printf "%-22s : %s\n" \
        "Pre-Update Backup" \
        "$(
            if [[ "${BACKUP_CREATED}" == true ]]; then
                printf "Completed"
            else
                printf "Not Created"
            fi
        )"

    printf "%-22s : %s\n" \
        "Deployment" \
        "$(
            if [[ "${DEPLOYMENT_COMPLETED}" == true ]]; then
                printf "Completed"
            else
                printf "Not Completed"
            fi
        )"

    print_separator

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "GitHub Readme Stats Update"

    printf "Version : %s\n\n" "${PROJECT_VERSION}"

    verify_update_workspace

    verify_repository_state

    fetch_upstream

    detect_update

    if [[ "${UPDATE_AVAILABLE}" != true ]]; then

        log_success "No update required."

        return 0
    fi

    create_pre_update_backup

    apply_update

    redeploy_application

    print_update_summary

    log_success "Application update completed successfully."

}

main "$@"