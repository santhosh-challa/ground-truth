

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

echo "Running Safety Latency Fitness Function..."

MAX_LATENCY_SECONDS=2

# These timestamps will be supplied by the staging synthetic safety-trip
# test (ADR-009) once staging hardware exists.
DETECTION_TIME="${DETECTION_TIME:-}"
ALARM_TIME="${ALARM_TIME:-}"

if [[ -z "$DETECTION_TIME" || -z "$ALARM_TIME" ]]; then
    skip "Safety latency (< ${MAX_LATENCY_SECONDS} s): specified in ADR-009, needs staging hardware"
fi

LATENCY=$(awk "BEGIN {print $ALARM_TIME - $DETECTION_TIME}")

echo "Measured safety latency: ${LATENCY} seconds"

if awk "BEGIN {exit !($LATENCY >= $MAX_LATENCY_SECONDS)}"; then
    echo "FAIL: Safety latency is ${LATENCY} seconds."
    echo "Required latency is below ${MAX_LATENCY_SECONDS} seconds."
    exit 1
fi

echo "PASS: Safety latency is below ${MAX_LATENCY_SECONDS} seconds."
