#!/bin/bash

set -e

CLOUD_MODELS_PATH=${1:-$CLOUD_MODELS_PATH}

if [ -z "${CLOUD_MODELS_PATH}" ]; then
    echo "Error: CLOUD_MODELS_PATH required"
    exit 1
fi

echo "uploading header model to ${CLOUD_MODELS_PATH}"

gsutil cp -Z "/opt/grobid/grobid-home/models/header/model.wapiti" \
    "${CLOUD_MODELS_PATH}/header/model.wapiti.gz"

gsutil ls -l "${CLOUD_MODELS_PATH}/header"
