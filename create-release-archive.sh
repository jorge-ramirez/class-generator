#!/bin/bash

###################################################################################################
# Script configuration
###################################################################################################

set -o nounset # exit on uninitialized variables
set -o errexit # exit for any non-true return values

###################################################################################################
# Variables
###################################################################################################

PROJECT_NAME="class-generator"
PROJECT_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
BUILD_DIR_PATH="$PROJECT_PATH/.build/release"
ZIP_FILE_PATH="$HOME/Desktop/$PROJECT_NAME.zip"

###################################################################################################
# Main script
###################################################################################################

# build the executable
swift build --configuration release -Xswiftc -static-stdlib

# zip the executable
cd "$BUILD_DIR_PATH"
zip "$ZIP_FILE_PATH" "$PROJECT_NAME"

# reveal the zip file in finder
open -R "$ZIP_FILE_PATH"
