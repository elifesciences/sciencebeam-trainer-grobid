#!/bin/bash

set -e

SOURCE_DATASET_DIR="/opt/grobid-source/grobid-trainer/resources/dataset"
TRAIN_DATASET_DIR="/opt/grobid/resources/dataset"
CLOUD_MODELS_PATH="${CLOUD_MODELS_PATH}"

DATASETS=()

echo "args: $@"

POSITIONAL=()
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --use-default-dataset)
        DATASETS+=("$SOURCE_DATASET_DIR")
        shift # past argument
        ;;

        --dataset)
        DATASETS+=("$2")
        shift # past argument
        shift # past value
        ;;

        --cloud-models-path)
        CLOUD_MODELS_PATH="$2"
        shift # past argument
        shift # past value
        ;;

        *)    # unknown option
        POSITIONAL+=("$1")
        shift # past argument
        ;;
    esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [ -z "${DATASETS}" ]; then
    echo "Error: no datasets enabled"
    exit 1
fi

echo "DATASETS=${DATASETS[@]}"

rm -rf "${TRAIN_DATASET_DIR}/header"
mkdir -p "${TRAIN_DATASET_DIR}/header"
cp -ar "${SOURCE_DATASET_DIR}/header/crfpp-templates" "$TRAIN_DATASET_DIR/header/crfpp-templates"

for dataset in ${DATASETS[@]}; do
    echo "dataset=$dataset"
    mkdir -p "${TRAIN_DATASET_DIR}/header/corpus/"
    gsutil -m cp -r "${dataset}/header/corpus/headers" "${TRAIN_DATASET_DIR}/header/corpus/"
    gsutil -m cp -r "${dataset}/header/corpus/tei" "${TRAIN_DATASET_DIR}/header/corpus/"
    gunzip -f "${TRAIN_DATASET_DIR}/header/corpus/headers/"*.gz || true
    gunzip -f "${TRAIN_DATASET_DIR}/header/corpus/tei/"*.gz || true
done

ls -l --recursive "${TRAIN_DATASET_DIR}/header"

if [ ! -d "/opt/grobid/grobid-home" ]; then
    echo "directory /opt/grobid/grobid-home not found, copying from source..."
    cp -ar "/opt/grobid-source/grobid-home" "/opt/grobid/grobid-home"
fi

java ${JAVA_OPTS} -jar grobid-trainer-onejar.jar \
    0 header \
    -gH /opt/grobid/grobid-home \
    $@

if [ ! -z "${CLOUD_MODELS_PATH}" ]; then
    upload-header-model.sh "${CLOUD_MODELS_PATH}"
fi
