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
    "segmentation/corpus/raw"
    "segmentation/corpus/tei"
    "segmentation/corpus/tei-raw"
    "segmentation/corpus/tei-auto"
    "header/corpus/headers"
    "header/corpus/tei"
    "header/corpus/tei-raw"
    "header/corpus/tei-auto"
    "fulltext/corpus/raw"
    "fulltext/corpus/tei"
    "fulltext/corpus/tei-raw"
    "fulltext/corpus/tei-auto"
    "figure/corpus/raw"
    "figure/corpus/tei"
    "figure/corpus/tei-raw"
    "figure/corpus/tei-auto"
    "reference-segmenter/corpus/raw"
    "reference-segmenter/corpus/tei"
    "reference-segmenter/corpus/tei-raw"
    "reference-segmenter/corpus/tei-auto"
    "affiliation-address/corpus"
    "affiliation-address/corpus-raw"
    "affiliation-address/corpus-auto"
    "citation/corpus"
    "citation/corpus-raw"
    "citation/corpus-auto"
    "name/citation/corpus"
    "name/citation/corpus-raw"
    "name/citation/corpus-auto"
    "name/header/corpus"
    "name/header/corpus-raw"
    "name/header/corpus-auto"
    "date/corpus"
    "date/corpus-raw"
    "date/corpus-auto"
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
