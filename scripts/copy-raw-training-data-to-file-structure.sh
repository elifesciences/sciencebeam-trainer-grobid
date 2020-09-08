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

has_matching_files() {
    local dir="$1"
    local pattern="$2"
    if test -n "$(find "${dir}" -maxdepth 1 -type f -name "${pattern}" -print -quit)"; then
        # echo "files exist: $dir $pattern"
        return
    fi
    # echo "files do not exist: $dir $pattern"
    false
}

mkdir_clean() {
    for dir in "$@"; do 
        echo "creating or cleaning directory: ${dir}"
        if [ -d "${dir}" ]; then
            if has_matching_files "${dir}" "*"; then
                rm "${dir}"/* || true
            fi
        else
            mkdir -p "${dir}"
        fi
    done
}

copy_and_rename_tei_and_raw_training_files() {
    local tei_dir="$1"
    local tei_pattern="$2"
    local raw_dir="$3"
    local raw_pattern="$4"

    if ! has_matching_files "$RAW_TRAINING_DATA_DIR" "${tei_pattern}"; then
        echo "no ${tei_pattern} data"
        return
    fi

    mkdir_clean "${tei_dir}" "${raw_dir}"

    echo "copying files from $RAW_TRAINING_DATA_DIR (${raw_pattern}) to $raw_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"${raw_pattern} "$raw_dir"
    rename 's#\.training\.#\.#' "$raw_dir"/*

    echo "copying files from $RAW_TRAINING_DATA_DIR (${tei_pattern}) to $tei_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"${tei_pattern} "$tei_dir"
    rename 's#\.training\.#\.#' "$tei_dir"/*
}

copy_segmentation_files() {
    copy_and_rename_tei_and_raw_training_files \
        "$DATASET_DIR/segmentation/corpus/tei-raw" \
        "*.segmentation.tei.xml" \
        "$DATASET_DIR/segmentation/corpus/raw" \
        "*.segmentation"
}

copy_header_files() {
    if [ -d "/opt/grobid-source/grobid-trainer/resources/dataset/header/corpus/headers" ]; then
        # prior GROBID 0.6.1
        copy_and_rename_tei_and_raw_training_files \
            "$DATASET_DIR/header/corpus/tei-raw" \
            "*.header.tei.xml" \
            "$DATASET_DIR/header/corpus/headers" \
            "*.header"
    else
        # from GROBID 0.6.1
        copy_and_rename_tei_and_raw_training_files \
            "$DATASET_DIR/header/corpus/tei-raw" \
            "*.header.tei.xml" \
            "$DATASET_DIR/header/corpus/raw" \
            "*.header"
    fi
}

copy_fulltext_files() {
    copy_and_rename_tei_and_raw_training_files \
        "$DATASET_DIR/fulltext/corpus/tei-raw" \
        "*.fulltext.tei.xml" \
        "$DATASET_DIR/fulltext/corpus/raw" \
        "*.fulltext"
}

copy_figure_files() {
    copy_and_rename_tei_and_raw_training_files \
        "$DATASET_DIR/figure/corpus/tei-raw" \
        "*.figure.tei.xml" \
        "$DATASET_DIR/figure/corpus/raw" \
        "*.figure"
}

copy_table_files() {
    copy_and_rename_tei_and_raw_training_files \
        "$DATASET_DIR/table/corpus/tei-raw" \
        "*.table.tei.xml" \
        "$DATASET_DIR/table/corpus/raw" \
        "*.table"
}

copy_reference_segmenter_files() {
    copy_and_rename_tei_and_raw_training_files \
        "$DATASET_DIR/reference-segmenter/corpus/tei-raw" \
        "*.referenceSegmenter.tei.xml" \
        "$DATASET_DIR/reference-segmenter/corpus/raw" \
        "*.referenceSegmenter"
}

copy_and_rename_tei_only_training_files() {
    local tei_dir="$1"
    local pattern="$2"

    if ! has_matching_files "$RAW_TRAINING_DATA_DIR" "${pattern}"; then
        echo "no ${pattern} data"
        return
    fi

    mkdir_clean "${tei_dir}"

    echo "copying files from $RAW_TRAINING_DATA_DIR (${pattern}) to $tei_dir"
    cp -a "$RAW_TRAINING_DATA_DIR/"${pattern} "$tei_dir"
    rename 's#\.training\.#\.#' "$tei_dir"/*
}

copy_affiliation_address_files() {
    copy_and_rename_tei_only_training_files \
        "$DATASET_DIR/affiliation-address/corpus-raw" \
        "*.affiliation.tei.xml"
}

copy_citation_files() {
    copy_and_rename_tei_only_training_files \
        "$DATASET_DIR/citation/corpus-raw" \
        "*.references.tei.xml"
}

copy_name_citation_files() {
    copy_and_rename_tei_only_training_files \
        "$DATASET_DIR/name/citation/corpus-raw" \
        "*.references.authors.tei.xml"
}

copy_name_header_files() {
    copy_and_rename_tei_only_training_files \
        "$DATASET_DIR/name/header/corpus-raw" \
        "*.header.authors.tei.xml"
}

copy_date_files() {
    copy_and_rename_tei_only_training_files \
        "$DATASET_DIR/date/corpus-raw" \
        "*.header.date.xml"
}

copy_segmentation_files
copy_header_files
copy_fulltext_files
copy_figure_files
copy_table_files
copy_reference_segmenter_files
copy_affiliation_address_files
copy_citation_files
copy_name_citation_files
copy_name_header_files
copy_date_files

ls -l --recursive "${DATASET_DIR}"
