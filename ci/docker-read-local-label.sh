#!/bin/bash
set -e

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 IMAGE LABEL"
    echo "Example: $0 elifesciences/annotations_cli org.elifesciences.dependencies.api-dummy"
    exit 1
fi

image="${1}"
label="${2}"
docker inspect "${image}" | jq -r ".[0].Config.Labels[\"${label}\"]"
