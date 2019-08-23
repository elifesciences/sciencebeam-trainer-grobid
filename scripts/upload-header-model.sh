#!/bin/bash

set -e

SCRIPT_HOME="$(dirname "$0")"

MODEL_NAME=header "${SCRIPT_HOME}/upload-model.sh" $@
