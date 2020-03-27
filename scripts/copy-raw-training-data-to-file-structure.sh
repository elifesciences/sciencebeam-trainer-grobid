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

mkdir_clean() {
    for dir in "$@"; do 
        echo "creating or cleaning directory: ${dir}"
        mkdir -p "${dir}"
        rm "${dir}"/* || true
    done
}

copy_segmentation_files() {
    segmentation_raw_dir="$DATASET_DIR/segmentation/corpus/raw"
    segmentation_tei_dir="$DATASET_DIR/segmentation/corpus/tei-raw"
    mkdir_clean "$segmentation_raw_dir" "${segmentation_tei_dir}"

    echo "copying files from $RAW_TRAINING_DATA_DIR to $segmentation_raw_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"*.segmentation "$segmentation_raw_dir"
    echo "renaming files $segmentation_raw_dir"
    rename 's#\.training\.#\.#' "$segmentation_raw_dir"/*

    echo "copying files from $RAW_TRAINING_DATA_DIR to $segmentation_tei_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"*.segmentation.tei.xml "$segmentation_tei_dir"
    rename 's#\.training\.#\.#' "$segmentation_tei_dir"/*
}

copy_header_files() {
    header_headers_dir="$DATASET_DIR/header/corpus/headers"
    header_tei_dir="$DATASET_DIR/header/corpus/tei-raw"
    mkdir_clean "$header_headers_dir" "${header_tei_dir}"

    echo "copying files from $RAW_TRAINING_DATA_DIR to $header_headers_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"*.header "$header_headers_dir"
    echo "renaming files $header_headers_dir"
    rename 's#\.training\.#\.#' "$header_headers_dir"/*

    echo "copying files from $RAW_TRAINING_DATA_DIR to $header_tei_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"*.header.tei.xml "$header_tei_dir"
    rename 's#\.training\.#\.#' "$header_tei_dir"/*
}

copy_reference_segmenter_files() {
    reference_segmenter_raw_dir="$DATASET_DIR/reference-segmenter/corpus/raw"
    reference_segmenter_tei_dir="$DATASET_DIR/reference-segmenter/corpus/tei-raw"
    mkdir_clean "$reference_segmenter_raw_dir" "${reference_segmenter_tei_dir}"

    echo "copying files from $RAW_TRAINING_DATA_DIR to $reference_segmenter_raw_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"*.referenceSegmenter "$reference_segmenter_raw_dir"
    echo "renaming files $reference_segmenter_raw_dir"
    rename 's#\.training\.#\.#' "$reference_segmenter_raw_dir"/*

    echo "copying files from $RAW_TRAINING_DATA_DIR to $reference_segmenter_tei_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"*.referenceSegmenter.tei.xml "$reference_segmenter_tei_dir"
    rename 's#\.training\.#\.#' "$reference_segmenter_tei_dir"/*
}

copy_segmentation_files
copy_header_files
copy_reference_segmenter_files

ls -l --recursive "${DATASET_DIR}"
