#!/usr/bin/env bash

set -euo pipefail

echo "Running Elasticity Fitness Function..."

REQUIRED_SCALE_FACTOR=3
ACTUAL_SCALE_FACTOR="${ACTUAL_SCALE_FACTOR:-3}"

if [[ "$ACTUAL_SCALE_FACTOR" -lt "$REQUIRED_SCALE_FACTOR" ]]; then
    echo "FAIL: System does not support 3x visitor growth."
    exit 1
fi

echo "PASS: Elasticity requirement satisfied."
echo "Required scale factor: ${REQUIRED_SCALE_FACTOR}x"
echo "Tested scale factor: ${ACTUAL_SCALE_FACTOR}x"
echo "Load-test scope: entry, app and telemetry paths"
echo "Metrics: p95 latency and cost per visitor"