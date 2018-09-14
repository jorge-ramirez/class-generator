#!/bin/bash

###################################################################################################
# Script configuration
###################################################################################################

set -o nounset # exit on uninitialized variables
set -o errexit # exit for any non-true return values

###################################################################################################
# Variables
###################################################################################################

EXAMPLE_DIRECTORY=$(cd `dirname $0` && pwd)
SCHEMAS_DIR_PATH="$EXAMPLE_DIRECTORY/schemas"
TEMPLATE_PATH="$EXAMPLE_DIRECTORY/templates/example-template.swift"
PLUGINS_DIR_PATH="$EXAMPLE_DIRECTORY/plugins"
CLASS_GENERATOR_PATH="$EXAMPLE_DIRECTORY/../.build/debug/class-generator"
OUTPUT_DIR_PATH=`mktemp -d`

###################################################################################################
# Main script
###################################################################################################

# build the project
swift build

# generate the classes
$CLASS_GENERATOR_PATH generate \
  "$SCHEMAS_DIR_PATH" \
  "$TEMPLATE_PATH" \
  --plugins-directory-path "$PLUGINS_DIR_PATH" \
  --output-directory-path "$OUTPUT_DIR_PATH" \
  --alphabetize-properties \
  --alphabetize-enum-values
