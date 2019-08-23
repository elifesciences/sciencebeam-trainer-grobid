#!/bin/bash

set -e

SCRIPT_HOME="$(dirname "$0")"

"${SCRIPT_HOME}/train-model.sh" --model "header" $@
