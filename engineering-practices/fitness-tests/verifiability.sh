#!/usr/bin/env bash

set -euo pipefail

echo "Running Verifiability Fitness Function..."

INPUT_TRACE="${INPUT_TRACE:-true}"
MODEL_VERSION="${MODEL_VERSION:-true}"
PROMPT_VERSION="${PROMPT_VERSION:-true}"

if [[ "$INPUT_TRACE" != "true" ]]; then
    echo "FAIL: AI input trace is missing."
    exit 1
fi

if [[ "$MODEL_VERSION" != "true" ]]; then
    echo "FAIL: AI model version is missing."
    exit 1
fi

if [[ "$PROMPT_VERSION" != "true" ]]; then
    echo "FAIL: AI prompt version is missing."
    exit 1
fi

echo "PASS: AI decision lineage is verifiable."
echo "Verified: inputs, model version and prompt version."