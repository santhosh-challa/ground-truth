# ADR-003: Model Monitoring & Drift Handling for Popularity Forecasting

Date: 2026-09-15

## Status
Accepted

## Context
The Popularity & Trend Scoring Service includes a forecasting model and an
anomaly detector that are, by nature, non-deterministic and subject to drift
as visitor patterns change over the estate's three-year growth plan (5,000 →
15,000 visitors/day). Investment decisions will be made based on this
output, so we need a defined way to know when the model's output can no
longer be trusted, without requiring a data scientist to manually inspect
every batch run.

### Alternatives
1. **No monitoring**: Retrain periodically on a fixed schedule and trust the
   output between retrains.
2. **Manual review**: An analyst periodically eyeballs the dashboard for
   anything that looks wrong.
3. **Automated drift detection with a human review gate**: The system
   continuously tracks model accuracy against ground truth and automatically
   flags degraded output for human review before it reaches the report.

### PrOACT

- **Problem**: How do we detect when the forecasting/anomaly model's output
  has drifted or degraded, before it silently corrupts an investment
  decision?

- **Objectives**:
  - Catch model degradation automatically rather than relying on someone
    noticing a bad number.
  - Keep the mechanism cheap enough to run every batch window, not just
    periodically.
  - Ensure a degraded model doesn't quietly get treated as ground truth by
    the Investment & Improvement Report.

- **Alternatives**: As described above.

- **Consequences**:
  - No monitoring: Cheapest, but drift could go unnoticed for months,
    directly undermining the credibility of investment recommendations.
  - Manual review: Better than nothing, but doesn't scale as the park grows
    to 15,000 visitors/day and more zones/assets are added, and is only as
    good as how carefully someone looks.
  - Automated drift detection with human gate: Highest upfront effort, but
    scales with the park and catches problems the moment they appear rather
    than whenever someone happens to notice.

- **Trade-offs**:
  - Upfront engineering cost vs. long-term trust: automated monitoring is
    more work to build now but is the only option that scales with growth
    and keeps the report defensible to investors.
  - Sensitivity vs. noise: an overly sensitive drift threshold produces
    constant false alarms; too lenient a threshold lets real drift through.

## Decision
Adopt **automated drift detection with a human review gate**. Every batch
run, the Scoring Service compares its forecast against the actual observed
footfall from the previous window (forecast error) and tracks whether
anomaly flags correlate with known operational events (maintenance closures,
weather, marketing pushes) where that data is available. If forecast error
or anomaly-flag reliability crosses a defined threshold over a rolling
window, the batch's ML annotations are suppressed from the report (falling
back to the rule-based baseline score only, per ADR-001) and the
Notification Service alerts an ops/data engineer for review.

## Tradeoffs - Mitigations
- **False positives suppressing useful trend data**: An overly sensitive
  threshold could regularly hide legitimate trend/anomaly insight.
  - *Mitigation*: Start with a conservative threshold calibrated against
    historical data before go-live, and tune it using the same feedback
    loop that reviews flagged drift events.

- **No ground truth for anomaly correlation in early deployment**: Without
  a log of known operational events, the anomaly-reliability check has
  nothing to compare against initially.
  - *Mitigation*: Launch with forecast-error tracking only (which needs no
    external ground truth), and add anomaly-correlation checks once an
    operational-events log exists.

- **Silent fallback going unnoticed**: If the ML layer is suppressed for
  weeks and nobody investigates, the report quietly loses its trend/anomaly
  value.
  - *Mitigation*: Surface fallback state directly on the Admin/Investment
    Dashboard (e.g. "trend insight temporarily unavailable — under review")
    rather than only alerting engineers, so business stakeholders can see
    and escalate if it persists.
