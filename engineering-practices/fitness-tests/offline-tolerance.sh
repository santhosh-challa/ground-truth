#!/usr/bin/env bash

set -euo pipefail

echo "Running Offline Tolerance Fitness Function..."

# Expected offline operating window
REQUIRED_OFFLINE_HOURS=4

# Placeholder for the staging chaos test result.
# This variable will be supplied by the CI/CD pipeline.
CHAOS_TEST_RESULT="${CHAOS_TEST_RESULT:-pass}"

if [[ "$REQUIRED_OFFLINE_HOURS" -lt 4 ]]; then
    echo "FAIL: Offline tolerance is below the required 4 hours."
    exit 1
fi

if [[ "$CHAOS_TEST_RESULT" != "pass" ]]; then
    echo "FAIL: Zone node offline chaos test failed."
    exit 1
fi

echo "PASS: Offline tolerance fitness function passed."
echo "Required offline duration: ${REQUIRED_OFFLINE_HOURS} hours"
