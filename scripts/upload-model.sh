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
    exit 1
fi

model_dir="${MODEL_NAME}"
if [ "${MODEL_NAME}" == "name-citation" ]; then
    model_dir="name/citation"
elif [ "${MODEL_NAME}" == "name-header" ]; then
    model_dir="name/header"
fi


echo "uploading ${model_dir} model to ${CLOUD_MODELS_PATH}"

LOCAL_MODEL_FILE="${GROBID_HOME}/models/${model_dir}/model.wapiti"

if [ ! -f "${LOCAL_MODEL_FILE}" ]; then
    echo "model file not found: ${LOCAL_MODEL_FILE}"
    exit 2
fi

cat "${LOCAL_MODEL_FILE}" \
    | gzip \
    | gsutil cp - "${CLOUD_MODELS_PATH}/${model_dir}/model.wapiti.gz"

gsutil ls -l "${CLOUD_MODELS_PATH}/${model_dir}"
