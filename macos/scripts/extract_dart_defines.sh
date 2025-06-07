#!/bin/bash

# this file is added to 'Run Script' in build phases.

# remove this custom implmenentation when flutter fix following issue:
# https://github.com/flutter/flutter/issues/139289

OUTPUT_FILE="${SRCROOT}/Flutter/ephemeral/GeneratedDartDefines.xcconfig"

# Echo empty to file.
>"$OUTPUT_FILE"

function decode_url() { echo "${*}" | base64 --decode; }

IFS=',' read -r -a define_items <<<"$DART_DEFINES"

for index in "${!define_items[@]}"; do
  item=$(decode_url "${define_items[$index]}")
  # Dart definitions also include items that are automatically defined on the Flutter side.
  # However, if we export those definitions, we will not be able to build due to errors, # so we do not output items that start with flutter or FLUTTER.
  lowercase_item=$(echo "$item" | tr '[:upper:]' '[:lower:]')
  if [[ $lowercase_item != flutter* ]]; then
    echo "$item" >>"$OUTPUT_FILE"
  fi
done
