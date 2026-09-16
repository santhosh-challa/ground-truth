# ADR-002: Idempotent Reconciliation Strategy for Zone Footfall Counts

Date: 2026-09-15

## Status
Accepted

## Context
Popularity scoring is only as trustworthy as the footfall counts feeding it.
Sensor retries, edge-gateway buffer replays after a Wi-Fi drop, and batch
re-runs from the Backfill Console all create opportunities for a visitor
count to be recorded twice, dropped, or attributed to the wrong window. Since
the whole use case depends on counts being right, we need an explicit,
enforced strategy for how the pipeline guarantees count integrity — not just
a hope that upstream devices behave.

### Alternatives
1. **Best-effort counting**: Accept occasional duplicate or missing counts as
   noise; no reconciliation step.
2. **Strict idempotent upsert + pre-processing reconciliation**: Every write
   is keyed so retries can never double-count, and a validation step checks
   extracted counts against source counts before any data proceeds to
   scoring.
3. **After-the-fact audit only**: Let data flow through unchecked, and
   periodically run an audit job to detect and correct discrepancies later.

### PrOACT

- **Problem**: How do we guarantee that a zone's footfall count reflects
  reality — not inflated by retries or deflated by dropped events — given
  that the same data can legitimately arrive more than once?

- **Objectives**:
  - Retries, buffer replays, and manual backfills must never inflate a
    zone's count.
  - Gaps or mismatches must be caught before they reach scoring, not
    discovered later in a report.
  - The mechanism must work automatically, without relying on someone
    noticing a suspicious number.

- **Alternatives**: As described above.

- **Consequences**:
  - Best-effort: Simplest, but accumulates silent errors — over months of
    retries, this could meaningfully distort which zones look "popular,"
    directly undermining the report's purpose.
  - Strict idempotent upsert + reconciliation: More upfront design work
    (key design, reconciliation logic), but count integrity becomes a
    property of the system rather than a hope.
  - After-the-fact audit: Catches errors eventually, but a "popular zone"
    ranking that was wrong for weeks before an audit runs can already have
    misdirected real investment decisions.

- **Trade-offs**:
  - Upfront rigor vs. speed to ship: strict reconciliation adds a validation
    step to every batch run, at the cost of some pipeline complexity.
  - False rejections vs. leniency: a reconciliation check that's too strict
    could dead-letter batches over trivial mismatches; too lenient and it
    misses real problems.

## Decision
Adopt **strict idempotent upsert + pre-processing reconciliation**. All
ingestion writes are upserted using a composite key of
`(device_id, zone_id, window)`, so a retried or replayed event overwrites
rather than duplicates. Before any batch proceeds to cleaning/aggregation,
the Validation Service reconciles the extracted record count against the
source count for that window and checks for schema violations, nulls, and
duplicate zone/timestamp entries. Any mismatch, gap, or duplicate routes the
batch to the Retry / Dead-Letter Handler instead of silently continuing.

## Tradeoffs - Mitigations
- **Reconciliation adds latency to every batch**: Checking counts before
  proceeding delays the pipeline compared to a fire-and-forget approach.
  - *Mitigation*: Since this is a batch pipeline (hourly/nightly), the
    added seconds of reconciliation are negligible against the batch window
    size — this is not a latency-sensitive path.

- **Legitimate late-arriving data looks like a "gap"**: A gateway recovering
  from a long outage flushes data after its original window has already
  been validated and closed.
  - *Mitigation*: Late-arriving events are written against their original
    `window` key (from event timestamp, not arrival time) and trigger a
    scoped re-validation/re-scoring of that specific historical window via
    the Backfill Console, rather than being silently dropped or
    misattributed to the current window.

- **Overly strict thresholds dead-lettering minor discrepancies**: A
  one-record mismatch shouldn't necessarily halt an entire batch.
  - *Mitigation*: Define a tolerance threshold (e.g. reconciliation fails
    only above a small percentage mismatch) so trivial noise doesn't
    generate constant false alarms, while still catching meaningful gaps.
