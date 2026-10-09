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

echo "Running Privacy Fitness Function..."

BIOMETRIC_API_SCAN="${BIOMETRIC_API_SCAN:-}"
IMAGE_EGRESS_TEST="${IMAGE_EGRESS_TEST:-}"

if [[ -z "$BIOMETRIC_API_SCAN" && -z "$IMAGE_EGRESS_TEST" ]]; then
    skip "Privacy: specified in README §6 and §17 (face-recognition library scan, imagery egress test)"
fi

if [[ "$BIOMETRIC_API_SCAN" != "pass" ]]; then
    echo "FAIL: Prohibited face-recognition/biometric API detected, or scan not run."
    exit 1
fi

if [[ "$IMAGE_EGRESS_TEST" != "pass" ]]; then
    echo "FAIL: Restricted imagery egress detected, or test not run."
    exit 1
fi

echo "PASS: Privacy fitness function passed."
echo "Biometric identification API scan: passed"
echo "Restricted imagery egress test: passed"
