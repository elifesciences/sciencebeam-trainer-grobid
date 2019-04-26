#!/bin/bash

set -e

DATASET_DIR=${1:-$DATASET_DIR}
CLOUD_DATATSET_PATH=${2:-$CLOUD_DATATSET_PATH}

if [ -z "${DATASET_DIR}" ]; then
    echo "Error: DATASET_DIR required"
    exit 1
fi

if [ -z "${CLOUD_DATATSET_PATH}" ]; then
    echo "Error: CLOUD_DATATSET_PATH required"
    exit 1
fi

echo "uploading dataset to ${CLOUD_DATATSET_PATH}"

gzip_and_upload() {
    source_dir="$1"
    target_dir="$2"
    temp_target=$(mktemp -d --suffix '-gzip')
    echo "temp_target: ${temp_target}"
    ls -l "${source_dir}"
    for filename in "${source_dir}/"*; do
        echo "filename: ${filename}"
        cat "${filename}" | gzip - > "${temp_target}/$(basename ${filename}).gz"
    done
    ls -l "${temp_target}"
    gsutil -m cp "${temp_target}/*" "${target_dir}/"
    rm -rf "${temp_target}"
}

echo "DATASET_DIR=${DATASET_DIR}"
echo "CLOUD_DATATSET_PATH=${CLOUD_DATATSET_PATH}"


sub_dirs=(
    "header/corpus/headers"
    "header/corpus/tei"
    "header/corpus/tei-raw"
    "header/corpus/tei-auto"
    "xml"
) 
for sub_dir in "${sub_dirs[@]}"; do
    if [ -d "${DATASET_DIR}/${sub_dir}" ]; then
        gzip_and_upload "${DATASET_DIR}/${sub_dir}" "${CLOUD_DATATSET_PATH}/${sub_dir}"
    else
        echo "no directory found (skipping): ${DATASET_DIR}/${sub_dir}"
    fi
done

echo "dataset uploaded to ${CLOUD_DATATSET_PATH}"

gsutil ls -l "${CLOUD_DATATSET_PATH}/**"
