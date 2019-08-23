#!/bin/bash

set -e

SOURCE_DATASET_DIR="/opt/grobid-source/grobid-trainer/resources/dataset"
TRAIN_DATASET_DIR="/opt/grobid/resources/dataset"
CLOUD_MODELS_PATH="${CLOUD_MODELS_PATH}"

DATASETS=()
MODEL_NAME=""

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

        --model)
        MODEL_NAME="$2"
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

if [ -z "${MODEL_NAME}" ]; then
    echo "Error: --model required"
    exit 1
fi

echo "DATASETS=${DATASETS[@]}"

if [ "${MODEL_NAME}" == "segmentation" ]; then
    sub_dirs=(
        "segmentation/corpus/raw"
        "segmentation/corpus/tei"
    )
elif [ "${MODEL_NAME}" == "header" ]; then
    sub_dirs=(
        "header/corpus/headers"
        "header/corpus/tei"
    )
else
    echo "Unsupported model: ${MODEL_NAME}"
    exit 2
fi

rm -rf "${TRAIN_DATASET_DIR}/${MODEL_NAME}"
mkdir -p "${TRAIN_DATASET_DIR}/${MODEL_NAME}"
cp -ar "${SOURCE_DATASET_DIR}/${MODEL_NAME}/crfpp-templates" "$TRAIN_DATASET_DIR/${MODEL_NAME}/crfpp-templates"

for dataset in ${DATASETS[@]}; do
    echo "dataset=$dataset"
    for sub_dir in "${sub_dirs[@]}"; do
        echo "copying ${dataset}/${sub_dir}..."
        mkdir -p "${TRAIN_DATASET_DIR}/${sub_dir}"
        gsutil -m cp "${dataset}/${sub_dir}/*" "${TRAIN_DATASET_DIR}/${sub_dir}/"
        gunzip -f "${TRAIN_DATASET_DIR}/${sub_dir}/"*.gz || true
    done
done

ls -l --recursive "${TRAIN_DATASET_DIR}/${MODEL_NAME}"

if [ ! -d "/opt/grobid/grobid-home" ]; then
    echo "directory /opt/grobid/grobid-home not found, copying from source..."
    cp -ar "/opt/grobid-source/grobid-home" "/opt/grobid/grobid-home"
fi

java ${JAVA_OPTS} -jar grobid-trainer-onejar.jar \
    0 "${MODEL_NAME}" \
    -gH /opt/grobid/grobid-home \
    $@

if [ ! -z "${CLOUD_MODELS_PATH}" ]; then
    upload-model.sh "${CLOUD_MODELS_PATH}" "${MODEL_NAME}"
fi
