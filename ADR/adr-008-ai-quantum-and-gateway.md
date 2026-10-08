# ADR-008: Start with one AI quantum containing the AI Gateway, AI evaluators and the model lifecycle

**Status:** Accepted

**Date:** 7 October 2026

## Context

AI features in our design include:
- feedback theme and sentiment evaluation
- keeper-note field extraction and evidence summaries
- popularity forecasting and anomaly detection
- the piranha counting pilot
- safety camera Layer 2

They all need the same things: provider access, fallback when a provider fails, cost limits, versioned models and prompts, and evaluation against ground truth (the Ground Truth Ledger).

Our documents disagreed about where this lives:
- README §5 lists the **AI Gateway as its own quantum**.
- [ADR-006](adr-006-ai-feedback-evaluation-and-reporting.md) placed the gateway **inside a unified feedback quantum**, together with collection and reporting.

The run team is small, and the number of AI capabilities is modest at launch. The AI landscape also changes every three to six months, which is faster than the rest of the estate changes.

## Options

1. **AI Gateway as its own quantum; each AI feature lives in its domain quantum.** Clean separation of provider access, but evaluation, model versioning and release logic get repeated in every domain. Too many moving parts at the start.
2. **Each domain calls providers directly.** Rejected: provider changes would touch every domain, cost and evaluation would be scattered, and nothing would stop safety-adjacent code calling an external model.
3. **One AI quantum containing the gateway, the AI evaluators and the model lifecycle.** Chosen as the starting point, with explicit triggers for splitting it later.

## Decision

We start with **one AI quantum**. It changes on the AI landscape's cadence, and the rest of the estate is insulated from that churn.

### What the AI quantum contains

| Part | Responsibility |
|---|---|
| **AI Gateway** | Binds capabilities to models; holds provider credentials; runs the fallback chain; enforces per-capability budgets and rate limits; validates structured outputs against a schema |
| **AI evaluators** | Generative and provider-backed capabilities that run inside this quantum: feedback theme and sentiment evaluator; keeper-note field extraction and evidence summaries |
| **Model lifecycle (Ground Truth Ledger)** | Model and prompt registry with pinned versions; golden sets; evaluation before release; drift monitoring; disposition capture. Governs **every** model, including the ones that run elsewhere (below) |

### What stays outside it

- **Feedback collection** (app and kiosk, PII stripping at the edge) and **deterministic reporting.** Reporting never calls a model. See ADR-006.
- **Critical alarms.** Deterministic, on the edge node, with no AI in the path. See [ADR-009](adr-009-critical-alarms-at-the-edge.md).
- **Ticketing.** AI-free by design. See [ADR-007](adr-007-ticketing-system.md).

### Self-hosted models: governed here, run where they belong

Some models don't use the gateway at all. They are **approved and released through the AI quantum's model lifecycle**, then **run inside the quantum that uses them**:

| Models | Type | Runs in | Why there |
|---|---|---|---|
| Piranha counting, safety camera Layer 2 | Edge vision (Tier A) | Zone edge nodes | Must keep working offline. Advisory only; never in a critical-alarm path |
| Popularity forecast and anomaly detection (ADR-001, ADR-003) | Classical ML on footfall time series (Tier B) | Footfall analytics pipeline, beside the rule-based baseline score | Runs on the data's batch schedule, needs no provider, and annotates the baseline it sits next to |

At runtime these models make **no call to the AI quantum**:
1. The consuming quantum pulls an approved model version from the registry.
2. It runs that model locally.
3. It sends predictions and outcomes back to the Ledger so drift can be scored.

If the AI quantum is unavailable, they keep running on the last approved version. The deterministic popularity baseline score is not a model and is not governed here.

### Rule of thumb

| If a capability… | Then |
|---|---|
| Calls an external or generative model | Runs in the AI quantum, through the AI Gateway |
| Is a self-hosted model (classical ML, edge vision, bandit) | Governed and released by the AI quantum; runs in the quantum that uses it |
| Is deterministic logic (baseline score, alarm rules, ticketing) | Not part of the AI quantum |

### How other quanta use it

- Domain quanta request a **capability by name** (for example `feedback.classify`, `notes.extract_fields`). They never name a provider or call one directly.
- Calls are asynchronous where possible, so an AI outage delays assistance rather than blocking a user.
- Every capability has a non-AI fallback, defined by its tier.

### Model tiers

| Tier | Covers | Hosting | If the provider disappears |
|---|---|---|---|
| **A** | Safety camera Layer 2, piranha counting | Self-hosted, open weights, version-pinned; runs on edge nodes | No impact. Never exposed to a provider |
| **B** | Forecasting and anomaly detection, recommender | Self-hosted (forecasting and anomaly detection run in the footfall analytics pipeline); deterministic or historical fallback is mandatory | Falls back to rules or history |
| **C** | Feedback evaluation, note extraction, summaries | Provider acceptable; a second provider and graceful degradation are required | Feature pauses or degrades; nothing critical is lost |

Budgets are set per capability, with an alert threshold below a hard cap.

### When to split the AI quantum

Split a capability (or the gateway) into its own quantum when any of these becomes true:
- It needs a different availability target or release schedule from the rest.
- An AI capability moves closer to a safety path and needs stricter change control.
- One capability dominates the quantum's load or cost.
- A separate team takes ownership.

## Consequences

**Benefits.**
- One place for provider access, cost control, versioning and evaluation, which fits a small team.
- The provider-swap story is a configuration change in one quantum.
- Domain quanta stay stable while models change.

**Costs.**
- One shared deployment, so a change to one capability redeploys the others. Mitigated by per-capability configuration, feature flags and versioned prompts.
- An outage of the AI quantum degrades every AI feature at once. Acceptable because every capability has a non-AI fallback and no critical path depends on it.
- Risk of becoming a bottleneck as use cases grow. Mitigated by the split triggers above.

## Enforcement

| Check | What it verifies | Evidence status |
|---|---|---|
| `no_direct_provider_calls` (planned) | No component outside the AI quantum declares a dependency on an external model provider | Planned |
| `tier_a_self_hosted` (planned) | Tier A capabilities are self-hosted and version-pinned | Planned |
| Second-provider contract test (planned) | Each Tier C capability passes its acceptance thresholds on its fallback provider. A shared interface alone does not prove equal quality | Planned |

## Changelog

- 7 October 2026: Proposed. Resolves the conflict between README §5 and ADR-006.
