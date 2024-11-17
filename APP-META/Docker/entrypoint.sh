#!/bin/bash

# shellcheck disable=SC1091

set -o errexit
set -o nounset
set -o pipefail
# set -o xtrace # Uncomment this line for debugging purposes

# Load app libraries
. /app/scripts/liblog.sh
# Load app environment variables
. /app/scripts/libenv.sh

print_welcome_page

if [[ "$*" = *"/app/scripts/run.sh"* || "$*" = *"/run.sh"* ]]; then
    info "** Starting APP setup **"
    #/app/scripts/setup.sh
    echo "here is something for setup..."
    info "** Complete APP setup **"
fi

echo ""
exec "$@"
