#!/bin/bash

###################################################################################################
# Builds and packages a universal macOS release archive.
#
# Usage:
#   Scripts/package-release.sh
#
# Set DIST_DIR to change where the archive is written. Defaults to <project>/dist.
###################################################################################################

set -o nounset # exit on uninitialized variables
set -o errexit # exit for any non-true return values
set -o pipefail

###################################################################################################
# Variables
###################################################################################################

PROJECT_NAME="class-generator"
PROJECT_PATH="$(cd "$(dirname "$0")/.." && pwd)"
VERSION_FILE_PATH="$PROJECT_PATH/Sources/class-generator/Version.swift"
DIST_DIR_PATH="${DIST_DIR:-$PROJECT_PATH/dist}"

VERSION="$(sed -n 's/.*static let current = "\([^"]*\)".*/\1/p' "$VERSION_FILE_PATH")"

if [[ -z "$VERSION" ]]; then
    echo "error: could not read Version.current from $VERSION_FILE_PATH" >&2
    exit 1
fi

ARCHIVE_NAME="$PROJECT_NAME-v$VERSION-macos-universal"
ARCHIVE_DIR_PATH="$DIST_DIR_PATH/$ARCHIVE_NAME"
ARCHIVE_PATH="$DIST_DIR_PATH/$ARCHIVE_NAME.zip"
CHECKSUM_PATH="$ARCHIVE_PATH.sha256"

###################################################################################################
# Main script
###################################################################################################

# build a universal release binary (Apple Silicon and Intel)
swift build --package-path "$PROJECT_PATH" --configuration release --arch arm64 --arch x86_64

# stage the archive contents
rm -rf "$ARCHIVE_DIR_PATH" "$ARCHIVE_PATH" "$CHECKSUM_PATH"
mkdir -p "$ARCHIVE_DIR_PATH"
cp "$PROJECT_PATH/.build/release/$PROJECT_NAME" "$ARCHIVE_DIR_PATH/"
cp "$PROJECT_PATH/LICENSE" "$PROJECT_PATH/README.md" "$ARCHIVE_DIR_PATH/"

# create the archive and its checksum
(
    cd "$DIST_DIR_PATH"
    ditto -c -k --norsrc --keepParent "$ARCHIVE_NAME" "$ARCHIVE_NAME.zip"
    shasum -a 256 "$ARCHIVE_NAME.zip" > "$ARCHIVE_NAME.zip.sha256"
)

echo "$ARCHIVE_PATH"
