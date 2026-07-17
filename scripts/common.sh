#!/usr/bin/env bash

###############################################################################
# Common Shell Utilities
#
# Shared utility library for deployment automation.
#
# Responsibilities:
#   - Logging
#   - Error handling
#   - Cleanup
#   - Dependency validation
#   - Shared helper functions
###############################################################################

set -Eeuo pipefail

###############################################################################
# Constants
###############################################################################

readonly SCRIPT_NAME="$(basename "${0}")"
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

###############################################################################
# Exit Codes
###############################################################################

readonly EXIT_SUCCESS=0
readonly EXIT_GENERAL_ERROR=1
readonly EXIT_INVALID_ARGUMENT=2
readonly EXIT_MISSING_DEPENDENCY=127

###############################################################################
# ANSI Colors
###############################################################################

if [[ -t 1 ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly CYAN='\033[0;36m'
    readonly NC='\033[0m'
else
    readonly RED=''
    readonly GREEN=''
    readonly YELLOW=''
    readonly BLUE=''
    readonly CYAN=''
    readonly NC=''
fi

###############################################################################
# Timestamp
###############################################################################

timestamp() {
    date '+%Y-%m-%d %H:%M:%S'
}

###############################################################################
# Logging
###############################################################################

log() {
    local level="$1"
    shift

    printf "%b[%s] [%s]%b %s\n" \
        "${CYAN}" \
        "$(timestamp)" \
        "${level}" \
        "${NC}" \
        "$*"
}

log_info() {
    log INFO "$@"
}

log_warn() {
    log WARN "$@"
}

log_success() {
    log SUCCESS "$@"
}

log_error() {
    log ERROR "$@" >&2
}

###############################################################################
# Error Handling
###############################################################################

die() {
    log_error "$@"
    exit "${EXIT_GENERAL_ERROR}"
}

error_handler() {
    local exit_code="$?"

    log_error "Command failed."

    log_error "Script : ${SCRIPT_NAME}"
    log_error "Line   : ${BASH_LINENO[0]}"
    log_error "Exit   : ${exit_code}"

    exit "${exit_code}"
}

trap error_handler ERR

###############################################################################
# Cleanup
###############################################################################

cleanup() {
    :
}

trap cleanup EXIT

###############################################################################
# Dependency Validation
###############################################################################

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

require_command() {

    local cmd="$1"

    if ! command_exists "${cmd}"; then
        die "Required command not found: ${cmd}"
    fi
}

###############################################################################
# Utility Helpers
###############################################################################

ensure_directory() {

    local directory="$1"

    mkdir -p "${directory}"
}

ensure_file() {

    local file="$1"

    touch "${file}"
}

copy_if_missing() {

    local source="$1"
    local destination="$2"

    if [[ ! -f "${destination}" ]]; then
        cp "${source}" "${destination}"
    fi
}

print_header() {

    printf "\n"
    printf "============================================================\n"
    printf "%s\n" "$1"
    printf "============================================================\n"
}

###############################################################################
# End of File
###############################################################################