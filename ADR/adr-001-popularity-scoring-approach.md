# ADR-001: Popularity & Trend Scoring Approach for Zone Analytics

Date: 2026-09-15

## Status
Accepted

## Context
Von Digitalis Estates has no visibility today into which zones (rides, animal
displays, plant collections) visitors actually spend time in. We need a
scoring approach that converts raw footfall + dwell-time data into a
popularity signal that is trustworthy enough to direct real investment
decisions, without becoming an unexplainable black box for non-technical
stakeholders (ops managers, investors).

### Alternatives
1. **Pure rule-based scoring**: Weighted combination of footfall count and
   average dwell time, ranked per zone/asset per window.
2. **Pure ML-based scoring**: A trained forecasting + anomaly-detection model
   produces the popularity/trend score directly, with no deterministic
   baseline.
3. **Hybrid scoring**: A deterministic rule-based baseline score, with an ML
   layer added on top purely for trend forecasting and anomaly detection.

### PrOACT

- **Problem**: How do we score zone/asset popularity in a way that is both
  accurate enough to catch emerging trends and explainable enough that an
  ops manager or investor trusts the ranking without needing to trust a
  model they can't inspect?

- **Objectives**:
  - Popularity scores must be explainable to non-technical stakeholders.
  - The system must catch slow declines and sudden anomalies, not just
    report a static count.
  - Scoring must degrade gracefully if the ML component is unavailable or
    untrusted (model drift, vendor outage).

- **Alternatives**: As described above.

- **Consequences**:
  - Pure rule-based: Fast to ship and fully explainable, but blind to
    trend/seasonality and can't flag "this is dropping faster than normal."
  - Pure ML-based: Best at catching trend and anomaly, but is a black box —
    hard to justify an investment decision with "the model said so," and
    fragile if the model drifts or the vendor changes behavior.
  - Hybrid: Slightly more implementation and maintenance work, but keeps a
    defensible baseline number at all times and only asks stakeholders to
    trust the ML layer for the "why is this trending" narrative, not the
    core ranking.

- **Trade-offs**:
  - Explainability vs. sophistication: the rule-based baseline sacrifices
    some accuracy on trend detection in exchange for a number anyone can
    verify by hand.
  - Maintenance vs. capability: the hybrid approach means running and
    monitoring two systems instead of one.

## Decision
Adopt a **hybrid scoring approach, rolled out in two phases** to account for
the fact that no historical footfall data exists on day one.

- **Phase 1 (launch)**: Run rule-based scoring only. The Popularity & Trend
  Scoring Service computes the deterministic baseline score from footfall +
  dwell time and populates the Investment & Improvement Report with this
  ranking alone. No forecast/anomaly layer runs yet — there isn't enough
  historical data for it to learn from.
- **Phase 2 (once sufficient history accumulates)**: Introduce the
  forecasting model and anomaly detector on top of the same enriched data,
  once enough batch windows of real footfall history exist to train and
  validate them meaningfully. The baseline score remains the primary
  ranking in the report; the ML layer only adds "trending up/down" and
  "unusual drop-off" annotations on top of it, never replacing it.

The exact amount of history required to enter Phase 2 (e.g. a minimum
number of weeks of footfall data per zone) is a model-training detail to be
set during implementation, not an architectural decision — but the
phased rollout itself is.

## Tradeoffs - Mitigations
- **Two systems to maintain**: Running rule-based and ML scoring in parallel
  doubles the surface area to test and monitor.
  - *Mitigation*: Keep the rule-based baseline intentionally simple (a
    documented formula, not a service of its own) so the maintenance burden
    stays concentrated on the ML layer.

- **Stakeholder confusion between the two scores**: Ops/investment staff may
  not understand why a "trending down" flag doesn't move the baseline
  ranking immediately.
  - *Mitigation*: Present both on the dashboard with a one-line explanation
    of what each measures, and clearly label the ML annotation as a
    forward-looking signal, not the current ranking.

- **Model drift silently degrading the trend/anomaly layer**: Covered in
  detail in ADR-003, but the mitigation here is architectural — the baseline
  score never depends on the ML layer being correct, so a drifted model
  degrades insight, not the core report.

- **Cold start — no historical data at launch**: An ML model trained on
  little or no real footfall history would produce unreliable, possibly
  misleading forecasts and anomaly flags from day one.
  - *Mitigation*: This is the reason for the phased rollout above — ship
    Phase 1 (rule-based only) at launch, and only enable the ML layer in
    Phase 2 once enough real history exists to train and validate it. The
    report is fully usable from day one on the baseline score alone; the
    trend/anomaly layer is additive, not a launch dependency.
