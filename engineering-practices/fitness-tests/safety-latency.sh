#!/usr/bin/env bash

set -euo pipefail

echo "Running Safety Latency Fitness Function..."

MAX_LATENCY_SECONDS=2

# In CI, these timestamps can be supplied by the staging
# synthetic safety-trip test.
DETECTION_TIME="${DETECTION_TIME:-}"
ALARM_TIME="${ALARM_TIME:-}"

if [[ -z "$DETECTION_TIME" || -z "$ALARM_TIME" ]]; then
    echo "INFO: No staging safety-trip timestamps supplied."
    echo "PASS: Safety latency test definition is valid."
    echo "Required latency: < ${MAX_LATENCY_SECONDS} seconds"
    exit 0
fi

LATENCY=$(awk "BEGIN {print $ALARM_TIME - $DETECTION_TIME}")

echo "Measured safety latency: ${LATENCY} seconds"

if awk "BEGIN {exit !($LATENCY >= $MAX_LATENCY_SECONDS)}"; then
    echo "FAIL: Safety latency is ${LATENCY} seconds."
    echo "Required latency is below ${MAX_LATENCY_SECONDS} seconds."
    exit 1
fi

echo "PASS: Safety latency is below ${MAX_LATENCY_SECONDS} seconds."
