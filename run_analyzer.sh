#!/bin/bash

${DART_SDK}/bin/dartanalyzer \
    --packages=.packages --package-warnings \
    --format=machine "$@" 2>&1 \
  | awk -F\| '$4 !~ /third_party\/dart-sdk/ { print $4 ":" $5 ":" $6 ": " ($1 == "INFO" ? "warning: hint" : tolower($1)) ":\n" $8 }'
