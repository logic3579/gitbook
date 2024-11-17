#!/bin/bash
#
# Environment configuration

# Base Dir
export APP_ROOT_DIR="/app/"

# Logging configuration
export MODULE_NAME="${MODULE_NAME:-template_app}"
export DEBUG_BOOL="${DEBUG_BOOL:-false}"

# Paths
export APP_CONFIG_DIR="${APP_ROOT_DIR}/config"
export APP_CONF_FILE="${APP_CONF_DIR}/config.yaml"
export APP_DATA_DIR="${APP_ROOT_DIR}/data"
export PATH="${PATH}:${APP_ROOT_DIR}/bin"

# System users (when running with a privileged user)
export APP_DAEMON_USER="app"
export APP_DAEMON_GROUP="app"

# Custom environment variables may be defined below
