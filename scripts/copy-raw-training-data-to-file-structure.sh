#!/bin/bash

set -e

echo "args: $@"

RAW_TRAINING_DATA_DIR=${1:-$RAW_TRAINING_DATA_DIR}
DATASET_DIR=${2:-$DATASET_DIR}

if [ -z "${RAW_TRAINING_DATA_DIR}" ]; then
    echo "Error: RAW_TRAINING_DATA_DIR required"
    exit 1
fi

if [ -z "${DATASET_DIR}" ]; then
    echo "Error: DATASET_DIR required"
    exit 1
fi

echo "RAW_TRAINING_DATA_DIR=${RAW_TRAINING_DATA_DIR}"
echo "DATASET_DIR=${DATASET_DIR}"

header_headers_dir="$DATASET_DIR/header/corpus/headers"
header_tei_dir="$DATASET_DIR/header/corpus/tei-raw"

mkdir -p "$header_headers_dir"
mkdir -p "$header_tei_dir"

rm "${header_headers_dir}"/* || true
rm "${header_tei_dir}"/* || true

echo "copying files from $RAW_TRAINING_DATA_DIR to $header_headers_dir"
cp -a "$RAW_TRAINING_DATA_DIR/"*.header "$header_headers_dir"
echo "renaming files $header_headers_dir"
rename 's#\.training\.#\.#' "$header_headers_dir"/*

echo "copying files from $RAW_TRAINING_DATA_DIR to $header_tei_dir"
cp -a "$RAW_TRAINING_DATA_DIR/"*.header.tei.xml "$header_tei_dir"
rename 's#\.training\.#\.#' "$header_tei_dir"/*

ls -l --recursive "${DATASET_DIR}"
