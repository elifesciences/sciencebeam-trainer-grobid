#!/bin/bash

set -e

GROBID_MODELS_DIRECTORY=${GROBID_MODELS_DIRECTORY:-/opt/grobid-source/grobid-home/models}

# override models via OVERRIDE_MODELS or OVERRIDE_MODELS_*
# the latter makes it easier to override multiple models as separate env variables
env -0 | while IFS='=' read -r -d '' env_var_name env_var_value; do
    if [[ -z "${env_var_value}" ]]; then
        # skip empty values
        continue
    fi
    if [[ "${env_var_name}" != "OVERRIDE_MODELS" ]] && [[ "${env_var_name}" != OVERRIDE_MODEL_* ]]; then
        # skipping other env variable names
        continue
    fi
    if [ ! -d "${GROBID_MODELS_DIRECTORY}" ]; then
        echo "directory does not exist: ${GROBID_MODELS_DIRECTORY}"
        exit 1
    fi
    echo "installing models: ${env_var_value} (${env_var_name})"
    python -m sciencebeam_trainer_grobid.tools.install_models \
        --model-base-path=${GROBID_MODELS_DIRECTORY} \
        --install "${env_var_value}" \
        --validate-pickles
done

exec "$@"
