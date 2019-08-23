#!/bin/bash

set -e

CLOUD_MODELS_PATH=${1:-$CLOUD_MODELS_PATH}
MODEL_NAME=${2:-$MODEL_NAME}

if [ -z "${CLOUD_MODELS_PATH}" ]; then
    echo "Error: CLOUD_MODELS_PATH required"
    exit 1
fi

if [ -z "${MODEL_NAME}" ]; then
    echo "Error: MODEL_NAME required"
    exit 1
fi

echo "uploading ${MODEL_NAME} model to ${CLOUD_MODELS_PATH}"

gsutil cp -Z "/opt/grobid/grobid-home/models/${MODEL_NAME}/model.wapiti" \
    "${CLOUD_MODELS_PATH}/${MODEL_NAME}/model.wapiti.gz"

gsutil ls -l "${CLOUD_MODELS_PATH}/${MODEL_NAME}"
