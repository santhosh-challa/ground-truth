# ADR-010: AI authority is set by risk and measured performance, not by default human approval

**Status:** Accepted

**Date:** 7 October 2026

## Context

Our actor analysis led to the rule that every AI action ends in "either a human approval step or a recorded evaluation". In practice the design defaulted to asking a person about almost everything; The Steward asks yes/no on every recommendation. That has two costs:

- **Staff attention is the scarcest resource on the estate.** Asking keepers, vets and managers to approve low-risk, reversible suggestions wastes it and trains them to click "yes" without reading.
- **It hides the real question:** how much authority has each AI capability *earned*, given what happens when it is wrong?

The opposite extreme, letting model confidence decide, is not safe either. Confidence is the model's own estimate. It can be miscalibrated, it can be confidently wrong on unfamiliar inputs, and a valid category can still be the wrong category.

This ADR covers **AI outputs** only. Critical alarms are deterministic and governed by [ADR-009](adr-009-critical-alarms-at-the-edge.md).

## Options

1. **A human approves every AI action.** Safe, but it doesn't scale, it fatigues staff, and it makes approvals meaningless.
2. **Model confidence above a threshold acts automatically.** Simple, but it trusts the model's view of itself and ignores harm and reversibility.
3. **Authority levels set by risk and measured performance.** Chosen.

## Decision

Each AI capability is assigned an **authority level**. The level is set by five factors:

| Factor | Question |
|---|---|
| **Harm if wrong** | What happens to an animal, a visitor, money or reputation if this output is wrong? |
| **Reversibility** | Can the action be undone cheaply and quickly? |
| **Measured performance** | How does it perform on a fixed, human-labelled evaluation set *and* on sampled production cases (Ground Truth Ledger)? |
| **Input health** | Are the inputs fresh, complete and within the range the model was evaluated on? |
| **Response capacity** | Do the people who would act on it have the capacity to respond? |

Model confidence is **one input** to "measured performance" (once its calibration has been checked on our data), not the rule.

### Authority levels

| Level | Meaning | Examples (initial assignment) |
|---|---|---|
| **L0 · Automatic** | Acts without notification; outcomes sampled into the Ledger | Wait-time display (as a range), itinerary suggestions within density caps, routine feedback tagging, popularity trend annotations, piranha count logged *as an estimate* |
| **L1 · Automatic with notice and undo** | Acts, tells the owner, can be reversed within a window | Routing feedback to a zone manager; a cleaning work order under a cost limit; a ±1 staffing nudge within budget; **pausing** a paid animal encounter when an advisory welfare concern is open |
| **L2 · Human approves** | Suggests; a named person decides | Pricing and bundle changes, marketing or "You spoke, we acted" emails, capital investment, **resuming** a paused encounter, keeper-note fields entering the record |
| **L3 · Human only; AI advises** | AI may frame evidence; it never proposes the action | Lockdown, evacuation, gate closure, all-clear, diagnosis and treatment |

**Principle:** *automate toward safety; require a human to relax it.* A system may pause an encounter on its own, but only a person may resume it.

### Changing a level

- **New capabilities start at L2** unless their harm is negligible, and are released through shadow mode first.
- **Promotion** (for example L2 → L1) needs measured performance above an agreed threshold on the fixed evaluation set and on production samples, held for an agreed period. The decision owner for that capability approves it.
- **Demotion is automatic** when the Ledger's monitors breach thresholds (accuracy, drift, input health). The capability drops one level and its owner is notified.
- **L3 is fixed.** No measured performance promotes a safety or medical decision out of human hands.

### Keeping the evidence honest

- Evaluation sets are **fixed and versioned**, separate from ongoing labels, so promotion thresholds are not tuned on the same data used to judge them.
- **Human dispositions are recorded with provenance.** Humans can be wrong, and can be influenced by the AI output they were shown.
- An AI model that checks another model's output is **another fallible model**, not ground truth.
- A small evaluation set is a demonstrator, not assurance: zero errors in 30 cases still allows an error rate of up to about 9.5%.

## Consequences

**Benefits.** Staff are asked only about decisions that matter. Every capability's authority is explicit and justified. The Steward can show *why* something happened automatically and who owns it.

**Costs.** Each capability needs a decision owner, a fixed evaluation set, production sampling and monitors before it can move above L2. Initial level assignments are judgments that the team and estate owners must review.

**Documents to update.**
- README §2.1 wording ("human approval step or a recorded evaluation") is restated as: authority by risk, with every automatic action sampled and recorded.
- The Steward's Recommendations screen shows each suggestion's level.

## Enforcement

| Check | What it verifies | Evidence status |
|---|---|---|
| `authority_matches_risk` (planned) | In the architecture model, any capability marked irreversible or high-harm is L2 or L3, every L0/L1 capability declares an undo path and a sampling rate, and safety actuation is L3 | Planned |
| Ledger demotion monitor (planned) | A threshold breach automatically lowers the capability's level and notifies its owner | Planned |

## Changelog

- 7 October 2026: Proposed. Responds to judge feedback on risk-based AI strategy and to the architect's point that low-risk decisions may not need a human in the loop.
- 8 October 2026: Accepted.
