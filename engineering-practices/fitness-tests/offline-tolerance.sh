
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

echo "Running Offline Tolerance Fitness Function..."

# Expected offline operating window
REQUIRED_OFFLINE_HOURS=4

# Result of the staging chaos test. It will be supplied by the pipeline
# once staging hardware exists.
CHAOS_TEST_RESULT="${CHAOS_TEST_RESULT:-}"

if [[ -z "$CHAOS_TEST_RESULT" ]]; then
    skip "Offline tolerance (${REQUIRED_OFFLINE_HOURS} h): specified in ADR-004, ADR-005 and ADR-009, needs staging hardware"
fi

if [[ "$CHAOS_TEST_RESULT" != "pass" ]]; then
    echo "FAIL: Zone node offline chaos test failed."
    exit 1
fi

echo "PASS: Offline tolerance fitness function passed."
echo "Required offline duration: ${REQUIRED_OFFLINE_HOURS} hours"
