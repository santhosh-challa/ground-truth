

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

echo "Running Provider Portability Fitness Function..."

CONTRACT_TEST_RESULT="${CONTRACT_TEST_RESULT:-}"

if [[ -z "$CONTRACT_TEST_RESULT" ]]; then
    skip "Provider portability: specified in ADR-008 (second-provider contract test)"
fi

if [[ "$CONTRACT_TEST_RESULT" != "pass" ]]; then
    echo "FAIL: Secondary provider contract test failed."
    exit 1
fi

echo "PASS: Provider portability contract test passed."
echo "Target: Tier C provider swap within one working day."
echo "Validation: Configuration-only provider change."
