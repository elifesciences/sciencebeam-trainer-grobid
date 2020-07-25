#!/bin/bash

set -e

CLOUD_FILE_LIST_PATH=${1:-$CLOUD_FILE_LIST_PATH}
PDF_DIR=${2:-$PDF_DIR}

if [ -z "${CLOUD_FILE_LIST_PATH}" ]; then
    echo "Error: CLOUD_FILE_LIST_PATH required"
    exit 1
fi

if [ -z "${PDF_DIR}" ]; then
    echo "Error: PDF_DIR required"
    exit 1
fi

echo "downloading dataset pdf from ${CLOUD_FILE_LIST_PATH} to ${PDF_DIR}"

mkdir -p "${PDF_DIR}"
gsutil cat "${CLOUD_FILE_LIST_PATH}" | gsutil -m cp -I "${PDF_DIR}/"
gunzip -f "${PDF_DIR}/"*.gz || true

ls -l "${PDF_DIR}/"
