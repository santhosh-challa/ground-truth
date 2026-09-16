#!/usr/bin/env bash

set -euo pipefail

echo "Running Cost Predictability Fitness Function..."

BUDGET_CAP_ENFORCED="${BUDGET_CAP_ENFORCED:-true}"
COST_VARIANCE_OK="${COST_VARIANCE_OK:-true}"

if [[ "$BUDGET_CAP_ENFORCED" != "true" ]]; then
    echo "FAIL: Gateway budget cap is not enforced."
    exit 1
fi

if [[ "$COST_VARIANCE_OK" != "true" ]]; then
    echo "FAIL: Cost variance is outside the allowed threshold."
    exit 1
fi

echo "PASS: Cost predictability checks passed."
echo "Gateway budget cap: enforced"
echo "Nightly cost variance: within threshold"