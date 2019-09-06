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

GROBID_HOME="/opt/grobid/grobid-home"
if [ ! -d "${GROBID_HOME}" ]; then
    GROBID_HOME="/data/grobid-home"
fi

if [ ! -d "${GROBID_HOME}" ]; then
    echo "no grobid home found (have you trained a model yet?)"
fi

echo "uploading ${MODEL_NAME} model to ${CLOUD_MODELS_PATH}"

gsutil cp -Z "${GROBID_HOME}/models/${MODEL_NAME}/model.wapiti" \
    "${CLOUD_MODELS_PATH}/${MODEL_NAME}/model.wapiti.gz"

gsutil ls -l "${CLOUD_MODELS_PATH}/${MODEL_NAME}"