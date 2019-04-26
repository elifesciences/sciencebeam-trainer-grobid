#!/bin/bash

set -e

CLOUD_DATATSET_PATH=${1:-$CLOUD_DATATSET_PATH}
PDF_DIR=${2:-$PDF_DIR}

if [ -z "${CLOUD_DATATSET_PATH}" ]; then
    echo "Error: CLOUD_DATATSET_PATH required"
    exit 1
fi

if [ -z "${PDF_DIR}" ]; then
    echo "Error: PDF_DIR required"
    exit 1
fi

echo "downloading dataset pdf from ${CLOUD_DATATSET_PATH}/pdf/ to ${PDF_DIR}"

mkdir -p "${PDF_DIR}"
gsutil -m cp "${CLOUD_DATATSET_PATH}/pdf/*" "${PDF_DIR}/"
gunzip -f "${PDF_DIR}/"*.gz || true

ls -l "${PDF_DIR}/"
