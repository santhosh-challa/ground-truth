
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

echo "Running Verifiability Fitness Function..."

INPUT_TRACE="${INPUT_TRACE:-}"
MODEL_VERSION="${MODEL_VERSION:-}"
PROMPT_VERSION="${PROMPT_VERSION:-}"

if [[ -z "$INPUT_TRACE" && -z "$MODEL_VERSION" && -z "$PROMPT_VERSION" ]]; then
    skip "Verifiability: specified in README §6 for ADR-003, ADR-006 and ADR-008 (audit sampler)"
fi

if [[ "$INPUT_TRACE" != "true" ]]; then
    echo "FAIL: AI input trace is missing."
    exit 1
fi

if [[ "$MODEL_VERSION" != "true" ]]; then
    echo "FAIL: AI model version is missing."
    exit 1
fi

if [[ "$PROMPT_VERSION" != "true" ]]; then
    echo "FAIL: AI prompt version is missing."
    exit 1
fi

echo "PASS: AI decision lineage is verifiable."
echo "Verified: inputs, model version and prompt version."
