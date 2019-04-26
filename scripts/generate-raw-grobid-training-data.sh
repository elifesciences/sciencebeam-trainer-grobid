#!/bin/bash

set -e

echo "args: $@"

PDF_DIR=${1:-$PDF_DIR}
RAW_TRAINING_DATA_DIR=${2:-$RAW_TRAINING_DATA_DIR}

if [ -z "${PDF_DIR}" ]; then
    echo "Error: PDF_DIR required"
    exit 1
fi

if [ -z "${RAW_TRAINING_DATA_DIR}" ]; then
    echo "Error: RAW_TRAINING_DATA_DIR required"
    exit 1
fi

echo "PDF_DIR=${PDF_DIR}"
echo "RAW_TRAINING_DATA_DIR=${RAW_TRAINING_DATA_DIR}"

mkdir -p "${RAW_TRAINING_DATA_DIR}"

java ${JAVA_OPTS} -jar grobid-core-onejar.jar \
    -gH /opt/grobid-source/grobid-home \
    -dIn "${PDF_DIR}" \
    -dOut "${RAW_TRAINING_DATA_DIR}" \
    -exe createTraining

ls -l "${RAW_TRAINING_DATA_DIR}"
