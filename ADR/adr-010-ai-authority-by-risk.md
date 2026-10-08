# ADR-010: AI authority is set by risk and measured performance, not by default human approval

**Status:** Accepted

**Date:** 7 October 2026


## Context

Our actor analysis led to the rule that every AI action ends in "either a human approval step or a recorded evaluation". In practice the design defaulted to asking a person about almost everything; The Steward asks yes/no on every recommendation. Asking a person to approve everything does not make the estate safer. It spends the scarcest resource on the estate, staff attention, and trains people to click "yes" without reading. It also hides the real question: how much authority has each AI capability *earned*, given what happens when it is wrong?

The opposite extreme, letting model confidence decide, is not safe either. Confidence is the model's own estimate. It can be miscalibrated, it can be confidently wrong on unfamiliar inputs, and a valid category can still be the wrong category.

Tiering ([ADR-008](adr-008-ai-quantum-and-gateway.md)) decides **where a model may run** and what happens if its provider disappears. Authority decides **what each capability is allowed to do** once it runs. Both apply to every capability, and they are recorded separately on purpose: a self-hosted Tier A model can still be advice-only, and a Tier C provider model can act on its own when being wrong is cheap and reversible.

**Scope.** This ADR covers **AI outputs** only, plus the welfare gate on paid encounters, because resuming an encounter is a human decision under the principle below. Critical alarms are deterministic and governed by [ADR-009](adr-009-critical-alarms-at-the-edge.md); they are not on this scale. Ticketing has no AI at all ([ADR-007](adr-007-ticketing-system.md)). The risk table also lists a few non-AI paths, marked **Not AI**, only so that the fallback beside each AI capability is visible.

## Options

1. **A human approves every AI action.** Safe, but it doesn't scale, it fatigues staff, and it makes approvals meaningless.
2. **Model confidence above a threshold acts automatically.** Simple, but it trusts the model's view of itself and ignores harm and reversibility.
3. **Authority levels set by risk and measured performance.** Chosen.

## Decision

Each AI capability gets an explicit authority level, set by what happens when it is wrong.

**How authority is set.** Five factors:

- **Harm if wrong:** to an animal, a visitor, money or reputation
- **Reversibility:** whether the action can be undone cheaply and quickly
- **Measured performance:** on a fixed, human-labelled evaluation set *and* on sampled production cases in the Ground Truth Ledger
- **Input health:** whether the inputs are fresh, complete and within the range the model was evaluated on
- **Response capacity:** whether the people who would act on it have the capacity to respond

Model confidence is one input to measured performance, and only once its calibration has been checked on our data. It is not the rule. A confident model on stale or unfamiliar input is still wrong.

> **Automate toward safety; require a human to relax it.**

The system may tighten on its own, for example by pausing a paid animal encounter. Loosening needs a named person: only a person may resume that encounter.

### Authority levels

| Level | Meaning |
|-------|---------|
| **L0 · Automatic** | Acts without notification. Outcomes are sampled into the Ledger |
| **L1 · Automatic with notice and undo** | Acts, tells the owner, and can be reversed within a window. Outcomes are sampled into the Ledger |
| **L2 · Human approves** | Suggests. A named person decides |
| **L3 · Human only; AI advises** | AI may frame evidence. It never proposes the action |

Critical alarms are not on this scale. They are deterministic rules on the zone edge node ([ADR-009](adr-009-critical-alarms-at-the-edge.md)). What is rated L3 is the human decision that follows an alarm: every lockdown, evacuation, gate closure and all-clear.

### Risk and authority table

Tiers A, B and C are defined in [ADR-008](adr-008-ai-quantum-and-gateway.md).

| Capability | If it's wrong | Authority | Guardrail | When it fails or is unavailable |
|------------|---------------|-----------|-----------|---------------------------------|
| **Critical life-support and safety alarms** (deterministic rules, ADR-009) | Animal or visitor harm | **Not AI; not on the scale.** Rules sound the alarm and page staff locally. The human decisions that follow (lockdown, evacuation, gate closure, all-clear) are **L3** | Thresholds owned by vets and the safety officer. Redundant probes, where disagreement is itself an alert. Stale-reading and heartbeat alarms. **Never alert-budgeted** | Fails loud. Operating restriction until restored: manual checks every 30 minutes, paid encounters paused, zone flagged on The Steward (ADR-009) |
| **Paid animal encounters** (welfare gate) | Animal stress, or lost revenue if over-cautious | **Pause: L1.** Automatic when a welfare concern is open, whether rules or AI raised it; owner notified. **Resume: L2.** Only a person | Revenue can never resume a session or raise a capacity ceiling | If the zone's edge node is down, encounters are paused as an operating restriction (ADR-009) |
| Advisory welfare concerns (configured rules + keeper observations) | Late attention, or alert fatigue | **Not AI.** Rules notify; the keeper or vet decides | Precision-first. Alert budget per role per day | Keeper rounds continue. Delayed readings are marked historical, not current, and staff see the age of the oldest unsent record ([ADR-004](adr-004-record-durability-and-sync.md), [ADR-005](adr-005-deployment-topology.md)) |
| Keeper-note field suggestions (Tier C) | A wrong field enters the animal's record | **L2.** Fields enter the record only after the keeper confirms or corrects them | Suggestions are stored separately from the original evidence and never overwrite it (ADR-004). Correction rate monitored | Manual entry; capture still works |
| AI evidence summaries for vets (Tier C) | Misleading framing of a concern | **L3** for what it supports: diagnosis and treatment are human only. The summary frames evidence; it never proposes treatment | Raw evidence shown first; output labelled as AI. Never needed to raise or act on an alarm (ADR-009). An AI checker would be another fallible model, not ground truth | Summary pauses; the concern and its evidence are still shown |
| Safety camera detection, Layer 2 (Tier A) | Missed or false detection | **L3.** Pre-stages the alert (location, still, severity) for the safety officer. Never in the actuation path | Never suppresses, delays or substitutes for a critical alarm (ADR-009). Shadow mode against staged drills before it is trusted. Recall-first. Image-quality and occlusion self-checks | Layer 1 continues alone. Degraded mode announced; staffing on affected zones increased |
| Piranha population count (Tier A, pilot) | A wrong picture of the population | **L0.** Logged *as an estimate* beside keeper counts | Interval, never a point estimate. Weekly manual spot count. Unusable views are never recorded as zero | Keeper counts only |
| Feedback tagging (Tier C) | Wrong theme or priority | **L0.** Tagged automatically against a fixed taxonomy | Fixed taxonomy (prevents *invalid* labels, not *wrong* ones). Agreement against a human-labelled sample (ADR-006) | Feedback buffered. Human triage queue |
| Feedback routing and small fixes (Tier C) | Wrong zone manager, or wasted maintenance spend | **L1.** Routes to a zone manager, or raises a cleaning work order under a cost limit; owner notified and can undo | Cost limit per work order. Submission zone and "zone it's about" kept separately (ADR-006) | Manual routing by staff |
| **Urgent safety or welfare reports in feedback** | A missed danger to a visitor or an animal | **Not AI.** Keyword rules and the visitor's "this is urgent" option go straight to zone staff ([ADR-006](adr-006-ai-feedback-evaluation-and-reporting.md)) | Never waits for, or depends on, AI evaluation. Staff review | Staff phone line; on-site signage |
| "You spoke, we acted" and marketing emails (Tier C) | A privacy breach or reputational harm | **L2.** A named person approves each send | Consent held separately from entitlements. PII is stripped before any model call (ADR-006) | Not sent |
| Attendance forecast → rostering (Tier B) | Queues and crowding, or wasted labour cost | **L1** for a ±1 staffing nudge within budget. **L2** for anything larger | Roster floor rules. Safety roles staffed to the upper forecast band. Must beat the seasonal baseline | Seasonal plan |
| Wait-time display and itinerary suggestions (Tier B) | Frustrated visitors, or herding them into a crowded zone | **L0.** Wait times shown as a range; suggestions within density caps | The safety layer's density cap is a hard constraint. Share cap per attraction. Held-out control group | Live queue counts and the popularity ranking |
| Popularity trends and anomalies (Tier B, Phase 2 only, [ADR-001](adr-001-popularity-scoring-approach.md)) | A wrong investment decision | **L0** for the annotation. **L2** for capital investment and pricing; the Countess decides | The rule score stays primary (ADR-001). Trends suppressed on drift ([ADR-003](adr-003-model-monitoring-and-drift.md)) | Rule score alone; the dashboard shows that trend insight is under review (ADR-003) |

### How a level changes

- **New capabilities start at L2**, unless their harm is negligible, and are released through shadow mode first.
- **Promotion** (for example L2 → L1) needs measured performance above an agreed threshold on the fixed evaluation set *and* on production samples, held for an agreed period. The capability's decision owner approves it.
- **Demotion is automatic.** When a Ledger monitor breaches its threshold (accuracy, drift or input health), the capability drops one level and its owner is notified. Where a capability's own ADR defines a fallback instead, that applies: popularity annotations are suppressed and the report falls back to the rule score ([ADR-003](adr-003-model-monitoring-and-drift.md)). An L2 capability that breaches falls back to its non-AI path ([ADR-008](adr-008-ai-quantum-and-gateway.md)); it never moves to L3, which is reserved for safety and medical decisions. The Ledger demotion monitor under Enforcement carries this out.
- **L3 is fixed.** No measured performance moves a safety or medical decision out of human hands.

### Keeping the evidence honest

- **Evaluation sets are fixed and versioned,** separate from ongoing labels, so promotion thresholds are never tuned on the same data used to judge them.
- **Human dispositions are recorded with provenance.** People can be wrong, and can be influenced by the AI output they were shown.
- **An AI model that checks another model's output is another fallible model,** not ground truth.
- **Small sets are demonstrators, not assurance.** Zero errors in 30 cases still allows an error rate of up to about 9.5%.

## Consequences

**Benefits.** Staff are asked only about decisions that matter. Every capability's authority is explicit and justified. The Steward can show *why* something happened automatically and who owns it.

**Costs.** Each capability needs a decision owner, a fixed evaluation set, production sampling and monitors before it can move above L2. Initial level assignments are judgments that the team and estate owners must review.

**Documents to update.**
- README §2.1 wording ("human approval step or a recorded evaluation") is restated as: authority by risk, with every automatic action sampled and recorded. *(Done.)*
- The Steward's Recommendations screen shows each suggestion's level.
- README §11 risk-profile table: add the rostering and cleaning work-order rows from the risk table above, and state on the L1 row that outcomes are sampled into the Ledger.

## Enforcement

| Check | What it verifies | Evidence status |
|---|---|---|
| `authority_matches_risk` (planned) | In the architecture model, any capability marked irreversible or high-harm is L2 or L3, every L0/L1 capability declares an undo path and a sampling rate, and safety actuation is L3 | Planned |
| Ledger demotion monitor (planned) | A threshold breach automatically lowers the capability's level, or applies its defined fallback, and notifies its owner | Planned |

Evidence status today: **Designed.** No authority level has yet been exercised on a running system.

## Changelog

- 7 October 2026: Proposed. Responds to judge feedback on risk-based AI strategy and to the architect's point that low-risk decisions may not need a human in the loop.
- 8 October 2026: Accepted.

