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

echo "Running Cost Predictability Fitness Function..."

BUDGET_CAP_ENFORCED="${BUDGET_CAP_ENFORCED:-}"
COST_VARIANCE_OK="${COST_VARIANCE_OK:-}"

if [[ -z "$BUDGET_CAP_ENFORCED" && -z "$COST_VARIANCE_OK" ]]; then
    skip "Cost predictability: specified in ADR-008 (gateway budget caps)"
fi

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
