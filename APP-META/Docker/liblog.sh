#!/bin/bash
#
# Library for logging functions

# Constants
RESET='\033[0m'
RED='\033[38;5;1m'
GREEN='\033[38;5;2m'
YELLOW='\033[38;5;3m'
MAGENTA='\033[38;5;5m'
CYAN='\033[38;5;6m'
BOLD='\033[1m'
#BLUE='\033[0;34m'
#PURPLE='\033[0;35m'

# Functions

########################
# Print to STDERR
# Arguments:
#   Message to print
# Returns:
#   None
#########################
stderr_print() {
    # 'is_boolean_yes' is defined in libvalidations.sh, but depends on this file so we cannot source it
    local bool="${STDERR_QUIET:-false}"
    # comparison is performed without regard to the case of alphabetic characters
    shopt -s nocasematch
    if ! [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
        printf "%b\\n" "${*}" >&2
    fi
}

########################
# Log message
# Arguments:
#   Message to log
# Returns:
#   None
#########################
log() {
    stderr_print "${CYAN}${MODULE:-} ${MAGENTA}$(date "+%T.%2N ")${RESET}${*}"
}
#########################
info() {
    log "${GREEN}INFO ${RESET} ==> ${*}"
}
#########################
warn() {
    log "${YELLOW}WARN ${RESET} ==> ${*}"
}
#########################
error() {
    log "${RED}ERROR${RESET} ==> ${*}"
}
#########################
debug() {
    #local bool="${DEBUG_BOOL:-false}"
    #shopt -s nocasematch
    #if [[ "$bool" = 1 || "$bool" =~ ^(yes|true)$ ]]; then
    #    log "${MAGENTA}DEBUG${RESET} ==> ${*}"
    #fi
    log "${MAGENTA}DEBUG${RESET} ==> ${*}"
}

########################
# Indent a string
# Arguments:
#   $1 - string
#   $2 - number of indentation characters (default: 4)
#   $3 - indentation character (default: " ")
# Returns:
#   None
#########################
indent() {
    local string="${1:-}"
    local num="${2:?missing num}"
    local char="${3:-" "}"
    # Build the indentation unit string
    local indent_unit=""
    for ((i = 0; i < num; i++)); do
        indent_unit="${indent_unit}${char}"
    done
    # shellcheck disable=SC2001
    # Complex regex, see https://github.com/koalaman/shellcheck/wiki/SC2001#exceptions
    echo "$string" | sed "s/^/${indent_unit}/"
}

########################
# Print the welcome page
#########################
print_welcome_page() {
    local github_url="https://github.com/xxx/xxx"
    log ""
    log "${BOLD}Welcome to the ${MODULE_NAME} container${RESET}"
    log "Subscribe to project updates by watching ${BOLD}${github_url}${RESET}"
    log "Submit issues and feature requests at ${BOLD}${github_url}/issues${RESET}"
    log ""
}
