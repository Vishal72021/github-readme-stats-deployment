#!/usr/bin/env bash

###############################################################################
# GitHub Readme Stats Deployment
#
# Backup Script
#
# Responsibilities
#   - Validate the backup workspace
#   - Verify the upstream repository state
#   - Capture repository metadata
#   - Create timestamped source backups
#   - Verify generated backup archives
#   - Apply backup retention policy
#   - Report backup results
#
# This script intentionally does NOT:
#   - Back up environment secrets
#   - Back up Docker containers
#   - Back up Docker images
#   - Modify the upstream repository
#   - Deploy or update the application
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
# Backup Runtime State
###############################################################################

BACKUP_TIMESTAMP=""
BACKUP_PATH=""
BACKUP_ARCHIVE=""
BACKUP_METADATA=""
BACKUP_COMMIT=""
BACKUP_BRANCH=""
BACKUP_REMOTE=""

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

verify_backup_workspace() {

    print_section "Verifying Backup Workspace"

    if [[ ! -d "${REPOSITORY_DIRECTORY}" ]]; then
        die \
            "Repository directory not found at " \
            "'${REPOSITORY_DIRECTORY}'. Run bootstrap.sh first."
    fi

    if [[ ! -d "${REPOSITORY_DIRECTORY}/.git" ]]; then
        die \
            "Repository directory exists but is not a Git repository."
    fi

    if ! run_git rev-parse --is-inside-work-tree \
        >/dev/null 2>&1; then

        die "Repository validation failed."
    fi

    mkdir -p "${BACKUP_DIRECTORY}" \
        || die "Failed to create backup directory '${BACKUP_DIRECTORY}'."

    log_success "Backup workspace verified."

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
            "Backup aborted to avoid capturing an inconsistent " \
            "repository state."
    fi

    log_success "Repository state verified."

}

###############################################################################
# Backup Creation
###############################################################################

create_backup() {

    print_section "Creating Repository Backup"

    BACKUP_TIMESTAMP="$(
        date -u +"%Y%m%dT%H%M%SZ"
    )"

    BACKUP_PATH="${BACKUP_DIRECTORY}/${BACKUP_TIMESTAMP}"

    BACKUP_ARCHIVE="${BACKUP_PATH}/${REPOSITORY_NAME}.tar.gz"

    BACKUP_METADATA="${BACKUP_PATH}/metadata.env"

    BACKUP_COMMIT="$(
        run_git rev-parse HEAD
    )" || die "Unable to determine repository commit."

    BACKUP_BRANCH="$(
        run_git branch --show-current
    )" || die "Unable to determine repository branch."

    BACKUP_REMOTE="$(
        run_git remote get-url "${UPSTREAM_REMOTE}"
    )" || die "Unable to determine repository remote."

    if [[ -z "${BACKUP_COMMIT}" ]]; then
        die "Repository commit could not be determined."
    fi

    if [[ -z "${BACKUP_BRANCH}" ]]; then
        die "Repository branch could not be determined."
    fi

    log_info "Creating backup directory..."

    mkdir -p "${BACKUP_PATH}" \
        || die "Failed to create backup directory '${BACKUP_PATH}'."

    log_info "Creating repository archive..."

    if ! tar \
        --exclude=".git" \
        --create \
        --gzip \
        --file "${BACKUP_ARCHIVE}" \
        --directory "${REPOSITORY_DIRECTORY}" \
        .; then

        rm -rf "${BACKUP_PATH}"

        die "Failed to create repository backup archive."
    fi

    log_info "Writing backup metadata..."

    if ! cat >"${BACKUP_METADATA}" <<EOF
BACKUP_TIMESTAMP=${BACKUP_TIMESTAMP}
REPOSITORY_NAME=${REPOSITORY_NAME}
REPOSITORY_BRANCH=${BACKUP_BRANCH}
REPOSITORY_COMMIT=${BACKUP_COMMIT}
REPOSITORY_REMOTE=${BACKUP_REMOTE}
EOF
    then

        rm -rf "${BACKUP_PATH}"

        die "Failed to create backup metadata."
    fi

    log_success "Repository backup created successfully."

}

###############################################################################
# Backup Verification
###############################################################################

verify_backup() {

    print_section "Verifying Repository Backup"

    if [[ ! -d "${BACKUP_PATH}" ]]; then
        die "Backup directory '${BACKUP_PATH}' was not created."
    fi

    if [[ ! -f "${BACKUP_ARCHIVE}" ]]; then
        die "Backup archive '${BACKUP_ARCHIVE}' was not created."
    fi

    if [[ ! -s "${BACKUP_ARCHIVE}" ]]; then
        die "Backup archive '${BACKUP_ARCHIVE}' is empty."
    fi

    if [[ ! -f "${BACKUP_METADATA}" ]]; then
        die "Backup metadata '${BACKUP_METADATA}' was not created."
    fi

    if [[ ! -s "${BACKUP_METADATA}" ]]; then
        die "Backup metadata '${BACKUP_METADATA}' is empty."
    fi

        log_info "Verifying backup archive integrity..."

    if ! tar \
        --list \
        --gzip \
        --file "${BACKUP_ARCHIVE}" \
        >/dev/null 2>&1; then

        die "Backup archive integrity verification failed."
    fi

    log_info "Verifying backup metadata..."

    if ! grep -q \
        "^BACKUP_TIMESTAMP=${BACKUP_TIMESTAMP}$" \
        "${BACKUP_METADATA}"; then

        die "Backup metadata timestamp verification failed."
    fi

    if ! grep -q \
        "^REPOSITORY_NAME=${REPOSITORY_NAME}$" \
        "${BACKUP_METADATA}"; then

        die "Backup metadata repository verification failed."
    fi

    if ! grep -q \
        "^REPOSITORY_BRANCH=${BACKUP_BRANCH}$" \
        "${BACKUP_METADATA}"; then

        die "Backup metadata branch verification failed."
    fi

    if ! grep -q \
        "^REPOSITORY_COMMIT=${BACKUP_COMMIT}$" \
        "${BACKUP_METADATA}"; then

        die "Backup metadata commit verification failed."
    fi

    if ! grep -q \
        "^REPOSITORY_REMOTE=${BACKUP_REMOTE}$" \
        "${BACKUP_METADATA}"; then

        die "Backup metadata remote verification failed."
    fi

    log_success "Repository backup verified successfully."

}

###############################################################################
# Backup Retention
###############################################################################

apply_backup_retention() {

    print_section "Applying Backup Retention"

    local -a backup_directories=()
    local backup_count
    local remove_count
    local backup_directory

    mapfile -t backup_directories < <(
        find "${BACKUP_DIRECTORY}" \
            -mindepth 1 \
            -maxdepth 1 \
            -type d \
            -printf '%f\n' \
            | sort -r
    )

    backup_count="${#backup_directories[@]}"

    if (( backup_count <= BACKUP_RETENTION_COUNT )); then

        log_info \
            "Backup retention limit not exceeded " \
            "(${backup_count}/${BACKUP_RETENTION_COUNT})."

        log_success "Backup retention policy applied."

        return
    fi

    remove_count=$((backup_count - BACKUP_RETENTION_COUNT))

    log_info \
        "Removing ${remove_count} backup(s) exceeding retention limit."

    for backup_directory in \
        "${backup_directories[@]:BACKUP_RETENTION_COUNT}"; do

        log_info "Removing old backup '${backup_directory}'."

        rm -rf \
            "${BACKUP_DIRECTORY:?}/${backup_directory}" \
            || die \
                "Failed to remove old backup '${backup_directory}'."

    done

    log_success "Backup retention policy applied."

}

###############################################################################
# Reporting
###############################################################################

print_backup_summary() {

    local archive_size

    archive_size="$(
        du -h "${BACKUP_ARCHIVE}" \
            | awk '{print $1}'
    )"

    print_separator

    printf "Backup Summary\n"

    print_separator

    printf "%-20s : %s\n" "Repository" "${REPOSITORY_NAME}"
    printf "%-20s : %s\n" "Branch" "${BACKUP_BRANCH}"
    printf "%-20s : %s\n" "Commit" "${BACKUP_COMMIT}"
    printf "%-20s : %s\n" "Timestamp" "${BACKUP_TIMESTAMP}"
    printf "%-20s : %s\n" "Archive" "${BACKUP_ARCHIVE}"
    printf "%-20s : %s\n" "Archive Size" "${archive_size}"
    printf "%-20s : %s\n" "Metadata" "${BACKUP_METADATA}"
    printf "%-20s : %s\n" "Retention" "${BACKUP_RETENTION_COUNT} backups"

    print_separator

}

###############################################################################
# Main
###############################################################################

main() {

    print_script_header "GitHub Readme Stats Backup"

    printf "Version : %s\n\n" "${PROJECT_VERSION}"

    verify_backup_workspace

    verify_repository_state

    create_backup

    verify_backup

    apply_backup_retention

    print_backup_summary

    log_success "Repository backup completed successfully."

}

main "$@"