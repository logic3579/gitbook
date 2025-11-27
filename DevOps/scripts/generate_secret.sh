#!/bin/bash

# Help info
### SCRIPT: generate_secret.sh
###
### DESCRIPTION:
###   Generates a random password of a specified length along with its SHA256 hash.
###
### USAGE:
###   ./generate_secret.sh -h
###   ./generate_secret.sh [PASSWORD_LENGTH]
###
### EXAMPLES:
###   ./generate_secret.sh         # Generate a default 13-character password
###   ./generate_secret.sh 32      # Generate a 32-character password

# Displays help information extracted from the header of this script.
function show_help() {
  # Use perl or sed to extract lines starting with '### '
  perl -ne 'print if s/^### ?//' "$0" || \
  sed -rn 's/^### ?//;T;p;' "$0"
  exit 0
}

# Logging functions for standardized output.
function log_info() {
  local message="$@"
  echo "[INFO] $message"
}
function log_warning() {
  local message="$@"
  echo "[WARNING] $message" >&2
}
function die_exit() {
  local message="$@"
  echo "[ERROR] $message" 1>&2
  exit 111
}

# Core logic to generate the password and hash, then print the results.
# It accepts the desired length as an argument.
function generate_and_print_secret() {
  local length=$1

  # Generate random bytes from /dev/urandom, encode them with base64,
  # and trim to the desired length. This is a reliable method for
  # generating secure random passwords.
  local password=$(base64 < /dev/urandom | head -c "$length")

  # Generate the SHA256 hash of the password.
  # Use 'echo -n' to prevent a trailing newline from being included in the hash.
  # Use 'awk '{print $1}'' to precisely extract the hash string.
  local hash=$(echo -n "$password" | sha256sum | awk '{print $1}')

  # --- Output Results ---
  echo "-------------------------"
  echo "Generated Password: ${password}"
  echo "SHA256 Hash:        ${hash}"
  echo "-------------------------"
}

# Check for help request first
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
  show_help
fi

# Parameter Processing and Validation
# Validate that the password length is a positive integer.
DEFAULT_LENGTH=13
PASSWORD_LENGTH=${1:-$DEFAULT_LENGTH}
if ! [[ "$PASSWORD_LENGTH" =~ ^[0-9]+$ ]]; then
    log_warning "Password length must be a positive integer."
    show_help
fi

# Execute the main function
generate_and_print_secret "$PASSWORD_LENGTH"

exit 0
