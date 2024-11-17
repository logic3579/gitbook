#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# am root
am_i_root() {
    if [[ "$(id -u)" = "0" ]]; then
        true
    else
        false
    fi
}
# Load Kafka environment variables
. /app/scripts/libenv.sh


START_COMMAND=("$APP_ROOT_DIR/bin/start.sh" "${flags[@]}" "$@")
info "** Starting App **"
if am_i_root; then
    exec gosu "$APP_DAEMON_USER" "${START_COMMAND[@]}"
else
    exec "${START_COMMAND[@]}"
fi
