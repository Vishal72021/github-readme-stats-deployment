#!/usr/bin/env bash
# shellcheck shell=bash

###############################################################################
# Common Utility Library
#
# Shared shell utilities used by deployment scripts.
#
# Responsibilities
#   - Logging
#   - Command helpers
#   - Filesystem helpers
#   - Retry helpers
#   - Formatting helpers
#
# This file intentionally contains NO project-specific configuration.
###############################################################################

set -o errexit
set -o nounset
set -o pipefail

###############################################################################
# Exit Codes
###############################################################################

readonly EXIT_SUCCESS=0
readonly EXIT_FAILURE=1

###############################################################################
# ANSI Colors
###############################################################################

if [[ -t 1 ]]; then
    readonly COLOR_RED="\033[0;31m"
    readonly COLOR_GREEN="\033[0;32m"
    readonly COLOR_YELLOW="\033[1;33m"
    readonly COLOR_BLUE="\033[0;34m"
    readonly COLOR_RESET="\033[0m"
else
    readonly COLOR_RED=""
    readonly COLOR_GREEN=""
    readonly COLOR_YELLOW=""
    readonly COLOR_BLUE=""
    readonly COLOR_RESET=""
fi

###############################################################################
# Timestamp
###############################################################################

timestamp() {

    date +"%Y-%m-%d %H:%M:%S"

}

###############################################################################
# Logging
###############################################################################

log() {

    local level="$1"
    shift

    printf "[%s] %-7s %s\n" \
        "$(timestamp)" \
        "${level}" \
        "$*"

}

log_info() {

    printf "%b[%s] INFO    %s%b\n" \
        "${COLOR_BLUE}" \
        "$(timestamp)" \
        "$*" \
        "${COLOR_RESET}"

}

log_success() {

    printf "%b[%s] SUCCESS %s%b\n" \
        "${COLOR_GREEN}" \
        "$(timestamp)" \
        "$*" \
        "${COLOR_RESET}"

}

log_warn() {

    printf "%b[%s] WARNING %s%b\n" \
        "${COLOR_YELLOW}" \
        "$(timestamp)" \
        "$*" \
        "${COLOR_RESET}"

}

log_error() {

    printf "%b[%s] ERROR   %s%b\n" \
        "${COLOR_RED}" \
        "$(timestamp)" \
        "$*" \
        "${COLOR_RESET}" >&2

}

###############################################################################
# Error Helpers
###############################################################################

die() {

    log_error "$*"
    exit "${EXIT_FAILURE}"

}

###############################################################################
# Formatting Helpers
###############################################################################

print_separator() {

    printf '%*s\n' 80 '' | tr ' ' '-'

}

print_header() {

    print_separator
    printf "%s\n" "$1"
    print_separator

}

print_section() {

    printf "\n==> %s\n\n" "$1"

}

###############################################################################
# Command Helpers
###############################################################################

command_exists() {

    command -v "$1" >/dev/null 2>&1

}

###############################################################################
# Filesystem Helpers
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

remove_if_exists() {

    local target="$1"

    if [[ -e "${target}" ]]; then
        rm -rf "${target}"
    fi

}

###############################################################################
# Retry Helper
###############################################################################

retry_command() {

    local retries="$1"
    local delay="$2"

    shift 2

    local attempt=1

    while true; do

        if "$@"; then
            return 0
        fi

        if (( attempt >= retries )); then
            return 1
        fi

        log_warn \
            "Attempt ${attempt}/${retries} failed. Retrying in ${delay}s..."

        sleep "${delay}"

        ((attempt++))

    done

}

###############################################################################
# Version Helper
###############################################################################

version_ge() {

    local current="$1"
    local minimum="$2"

    [[ "$(printf '%s\n%s\n' "${minimum}" "${current}" | sort -V | head -n1)" == "${minimum}" ]]

}

###############################################################################
# Platform Helpers
###############################################################################

is_wsl() {

    grep -qi microsoft /proc/version 2>/dev/null

}

###############################################################################
# User Confirmation
###############################################################################

confirm() {

    local prompt="${1:-Continue?}"

    read -r -p "${prompt} [y/N]: " reply

    [[ "${reply}" =~ ^[Yy]([Ee][Ss])?$ ]]

}

###############################################################################
# End of File
###############################################################################