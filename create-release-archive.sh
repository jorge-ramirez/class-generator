#!/bin/bash

###################################################################################################
# Builds the release archive on the Desktop and reveals it in Finder.
#
# This is a convenience wrapper around Scripts/package-release.sh. Official releases are published
# by the Release GitHub Actions workflow when a version tag is pushed.
###################################################################################################

set -o nounset # exit on uninitialized variables
set -o errexit # exit for any non-true return values
set -o pipefail

###################################################################################################
# Variables
###################################################################################################

PROJECT_PATH="$(cd "$(dirname "$0")" && pwd)"

###################################################################################################
# Main script
###################################################################################################

ARCHIVE_PATH="$(DIST_DIR="$HOME/Desktop" "$PROJECT_PATH/Scripts/package-release.sh")"

open -R "$ARCHIVE_PATH"
