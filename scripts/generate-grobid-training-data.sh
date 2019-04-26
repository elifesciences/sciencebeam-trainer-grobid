#!/bin/bash

set -e

echo "args: $@"

PDF_DIR=${1:-$PDF_DIR}
DATASET_DIR=${2:-$DATASET_DIR}

if [ -z "${PDF_DIR}" ]; then
    echo "Error: PDF_DIR required"
    exit 1
fi

if [ -z "${DATASET_DIR}" ]; then
    echo "Error: DATASET_DIR required"
    exit 1
fi

echo "PDF_DIR=${PDF_DIR}"
echo "DATASET_DIR=${DATASET_DIR}"

RAW_TRAINING_DATA_DIR=/tmp/raw-training-data

rm -rf "${RAW_TRAINING_DATA_DIR}"

generate-raw-grobid-training-data.sh "${PDF_DIR}" "${RAW_TRAINING_DATA_DIR}"
copy-raw-training-data-to-file-structure.sh "${RAW_TRAINING_DATA_DIR}" "${DATASET_DIR}"
