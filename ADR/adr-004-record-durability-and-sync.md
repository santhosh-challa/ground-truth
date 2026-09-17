# ADR-004: Save every record at its origin before confirming, then synchronise when connected

**Status:** Accepted

**Created:** 12 September 2026

## Context

Our selected use cases are animal health monitoring, footfall/popularity, and ticketing, with AI features built around them. Wi-Fi on the estate is patchy. The brief allows cloud services and provides a budget for MQTT-capable hardware.

Records originate in many places: a keeper's tablet, an enclosure sensor, a people counter, a gate scanner, a staffed lane issuing a cash ticket. Each origin may lose its link to the next hop at any time, and the estate as a whole may lose its link to the cloud. These are two separate failures. A record must survive whichever one happens.

Not every record has the same urgency. A feeding note can upload later. A footfall report can show delayed counts. A gate admission needs a local decision now. This ADR sets the rule every record follows regardless of where it is decided. Where processing runs is [ADR-005](adr-005-deployment-topology.md).

## Constraints from organizers

- Historical data exists only as paperwork and staff experience.
- Device-type assumptions are permitted if documented.
- Cost trade-offs are expected at a high level: upfront spend versus ongoing spend that can be stopped if it does not pay off.

## Assumptions

- At least one link exists from each origin to the cloud, possibly intermittent. Which links exist is a design choice recorded in ADR-005.
- Origin devices have enough local storage to hold an agreed disconnection window. Devices that do not are treated as lossy and documented as such.

## Decision

Every record is written durably at its origin before any success is reported to a person or a caller. It is then forwarded to the next hop when a connection exists. No record depends on a live link to be captured. This applies equally to records the cloud did not create, such as a ticket issued at a gate.

### Acknowledged, idempotent delivery

Each record carries a stable identifier assigned at the origin and its original observation time. The origin keeps its copy until the next hop confirms durable receipt. A protocol level acknowledgement is not that confirmation. Receivers enforce uniqueness on the identifier, so resending never creates a second feeding entry, count, admission or ticket. A late upload is never mistaken for a current reading. Corrections and AI generated assessments are stored separately from the original evidence, reference it, and never overwrite it.

An origin therefore knows three states for each record: saved here, received by the next hop, received by the cloud. Anything shown to a person reflects the true state.

### Bounded buffer, watched

Local storage is finite. For each origin type we state how long a disconnection it must cover, what happens when the buffer fills (stop, overwrite oldest, or alert), and how quickly the backlog must drain once reconnected. Each origin reports pending count, age of oldest unsent record, last successful sync, and storage failures. Any report or dashboard built on forwarded records shows the freshness of its inputs and marks periods with missing or delayed data. 

### Security

Device access, local buffers and transfers are authenticated and encrypted. Local buffers may hold personal or payment adjacent data. 

## Consequences

**Benefits:** recording continues through any outage. Late data arrives with its true timestamp and cannot be double counted. Backlog metrics give a direct, testable signal that the mechanism is working.

**Costs:** every origin needs storage, a sync client, and a recovery procedure. Cloud reports may lag reality and must say so. A buffer that fills still loses data. The design bounds the loss, it does not eliminate it. Store and forward preserves a record but cannot act on it during the outage. 
Any record that needs a decision during disconnection needs a local decision point.

**Ownership:** the origin owns a record until the next hop confirms receipt. After that the receiving service owns it and the origin may discard its copy.

## Alternatives considered

1. **Send every record straight to the cloud and accept loss during outages.** Simplest infrastructure. Rejected: the brief states Wi-Fi is patchy, so loss would be routine rather than exceptional, and lost animal observations or admissions cannot be reconstructed from paperwork.
2. **Invest in coverage so devices stay connected.** Worth doing at gates and cameras regardless, but coverage improvement makes outages rarer, not absent. Kept as a complement, not a substitute.
3. **Rely on the transport's own delivery guarantee as confirmation.** Rejected: delivery to a broker is not the same as the business record being durably processed. A broker or downstream service can still fail after acknowledging.
