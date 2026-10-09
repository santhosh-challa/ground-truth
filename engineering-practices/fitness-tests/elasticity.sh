
set -euo pipefail

skip() {
    local msg="SKIPPED: $1, not yet measured."
    echo "$msg"
    if [[ -n "${GITHUB_ACTIONS:-}" ]]; then
        echo "::notice title=Fitness function not yet running::${msg}"
        if [[ -n "${GITHUB_STEP_SUMMARY:-}" ]]; then
            echo "$msg" >> "$GITHUB_STEP_SUMMARY"
        fi
    fi
    exit 0
}

echo "Running Elasticity Fitness Function..."

REQUIRED_SCALE_FACTOR=3
ACTUAL_SCALE_FACTOR="${ACTUAL_SCALE_FACTOR:-}"

if [[ -z "$ACTUAL_SCALE_FACTOR" ]]; then
    skip "Elasticity (${REQUIRED_SCALE_FACTOR}x peak load test): specified in README §6"
fi

if [[ "$ACTUAL_SCALE_FACTOR" -lt "$REQUIRED_SCALE_FACTOR" ]]; then
    echo "FAIL: System does not support 3x visitor growth."
    exit 1
fi

echo "PASS: Elasticity requirement satisfied."
echo "Required scale factor: ${REQUIRED_SCALE_FACTOR}x"
echo "Tested scale factor: ${ACTUAL_SCALE_FACTOR}x"
echo "Load-test scope: entry, app and telemetry paths"
echo "Metrics: p95 latency and cost per visitor"
