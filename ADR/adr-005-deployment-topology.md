# ADR-005: Cloud primary deployment with local admission and critical alarms

**Status:** Accepted

**Created:** 12 September 2026

**Amended:** 7 October 2026 (see Changelog)

## Context

The selected use cases are animal health monitoring, footfall/popularity, and ticketing. Wi-Fi on the estate is patchy. The brief permits cloud services and provides a budget for MQTT-capable devices.
[ADR-004](adr-004-record-durability-and-sync.md) decides that every record is saved at its origin and forwarded when connected. That preserves records but cannot act on them during an outage. This ADR decides which functions run in the cloud, which run on the estate, and which run on the device itself, and why.


## Constraints from organizers

- Cost trade offs are expected at a high level: upfront spend versus ongoing spend that can be stopped.
- Historical data exists only as paperwork and staff experience.
- Device type assumptions are permitted if documented.

## Assumptions

- **A1. A dedicated gate network exists** (wired or a dedicated access point) that is more reliable than the estate's internet uplink. If false, the admission coordinator is no more available than the scanners' own caches and should be dropped.
- **A2. Advisory sensors use LoRaWAN. Critical sensors, counters, cameras and scanners use IP** (Ethernet or suitable Wi-Fi). LoRaWAN payloads are small and regionally duty cycle limited, which suits periodic advisory readings but not critical alarms ([ADR-009](adr-009-critical-alarms-at-the-edge.md)).
- **A3. The budgeted MQTT devices are sensors, counters and gateways**. 
- **A4. Keepers round every enclosure at least every 2 hours.** This is a care procedure. It is not the control for critical conditions, which raise local alarms under ADR-009, and it does not bound the delay of advisory concerns during an outage.

## Decision

The application runs in the cloud. Functions that must keep working while the internet uplink is down run on the estate: admission at the gates, critical alarms, buffering of device telemetry, and approved edge AI inference such as camera counting. Everything else is either cloud-hosted or device-local.

### Placement rule

| Placement | What runs there | Test |
|---|---|---|
| **Device** | Hardwired reflexes: ride emergency stops in the ride's own control circuit, sensor sampling, on-device counting | Must work with no network at all |
| **Estate edge** (zone edge nodes, gate network) | Anything that must survive an internet outage: admission, critical alarms (ADR-009), telemetry buffering, approved edge AI inference ([ADR-008](adr-008-ai-quantum-and-gateway.md)) | Must work with the uplink down |
| **Cloud** | Anything that can wait: records, history, advisory welfare concerns, analytics, model training and evaluation, AI assistance | May pause during an outage; reports show input freshness |

### What runs where

| Function | Placement | Reason |
|---|---|---|
| Online ticket purchase, payment, issuance | Cloud (ticketing service + hosted payment provider) | Payment providers are cloud hosted. The public buys before arriving. |
| **Admission validation** | Gate scanners + **local admission coordinator** on the gate network | Must work during a WAN outage. Scanners hold a downloaded manifest (valid tickets, family-pass counts, revocations). The coordinator holds the shared admission log so gates agree on what is already used, which matters most for family-pass counts. It also issues capacity leases ([ADR-007](adr-007-ticketing-system.md)). If a scanner cannot reach the coordinator, it validates from its own cache and accepts a known duplicate window. That ticket group is routed to one designated scanner. Duplicates are visible on resync but cannot be undone. |
| **Walk-up sales** | Staffed lane, cash only | Ticket issued at the gate with a stable ID, admitted, registered with the coordinator, synced under ADR-004. The cloud ticketing service accepts gate issued tickets as a distinct origin. End of day control: cash taken reconciles to gate issued tickets. Card store and forward (deferred authorization) is deferred as a later option. |
| **Critical alarms** (dissolved oxygen, water temperature, pump/flow, water level, enclosure or barrier breach, emergency stops) | **Zone edge node** | Deterministic rules on the edge node sound the local siren and page staff with no cloud dependency. Resilience and operating restrictions are in ADR-009. |
| Sensor readings (enclosure, aquatic) | Critical sensors → edge node over IP. Advisory sensors → LoRaWAN gateway. Both → **edge MQTT broker with offline buffer** → cloud | The broker is the single estate to cloud path for device telemetry. It persists messages to disk while the uplink is down and publishes when it returns. Candidates: HiveMQ Edge, EMQX Edge. Either is replaceable by the other. |
| Advisory welfare concerns | Cloud evaluated | Configured rules on non-critical readings, reviewed by keepers and vets. During an outage these concerns are delayed and marked as historical when they arrive. The "age of oldest unsent record" metric from ADR-004 is shown to staff so they know when advisory alerting is blind. Critical conditions do not wait for this path (ADR-009). |
| Keeper/vet notes and observations | Tablet, synced direct to cloud | Second path to cloud, deliberately bypassing the broker. Tablets already have storage and an HTTP client, and notes carry attachments the broker path is not for. |
| Footfall counting | On the counter or camera | Only counts leave the device. Video never leaves the estate except selected clips retained locally for count validation. |
| Footfall reports and forecasts | Cloud | Historical analysis tolerates delay. Reports show input freshness per ADR-004. |
| Animal records, shared history, reporting | Cloud | One place to change behaviour and keep long term records. |
| AI quantum (gateway, evaluators, model lifecycle) | Cloud, with approved models running on edge nodes | Assistance can pause during outages. Edge models keep working offline. See ADR-008. |

Two paths reach the cloud: broker-buffered telemetry, and direct device sync (tablets, scanners, staffed lane). Both obey ADR-004.

## Consequences

**Benefits:**
- Most operational change happens in one place.
- Recording, admission, cash sales and critical alarms continue through an uplink outage.
- The MQTT device budget is exercised through a standard, replaceable component rather than bespoke buffering.
- Owning the ticketing service keeps gate issued tickets and online tickets in one model.

**Costs:**
- The coordinator, broker and zone edge nodes are estate hosts that need power, patching, backup and a restart procedure. Edge nodes carrying critical alarms also need a UPS, a watchdog and peer monitoring (ADR-009).
- Cloud history, advisory concerns and AI assistance are unavailable during outages, and local copies go stale.
- Offline broker buffering may be a licensed feature depending on the product chosen. Treat it as stoppable opex.
- The gate network (A1) is a single point of failure for coordinated admission.

## Alternatives considered

| Alternative | Capex | Stoppable opex | Availability during WAN outage | Ops burden on estate | Verdict |
|---|---|---|---|---|---|
| **Chosen: cloud-primary, coordinator + edge broker + edge-node alarms** | Med | Med | Recording, admission, cash sales and critical alarms continue. Advisory concerns and AI pause | Med (estate hosts) | Accepted |
| Cloud only, device caches, no estate hosts | Low | Low | Recording continues. Admission per scanner only, cross gate duplicates until resync. No critical alarms during outage | Lowest | Rejected for family passes and critical alarms |
| Cloud-primary plus second internet link (cellular backup) | Med | Med–High (recurring carrier) | Higher, but dual carrier and power failures still occur | Low | Complementary, not a substitute. Keep the outage procedure regardless |
| Most services on the estate | High | Low | Highest | High (hosting, DB, backup, remote access) | Rejected| 
| Full application in both places | Highest | High | Highest | Highest (state reconciliation) | Rejected |

## Enforcement

| Check | What it verifies | Evidence status |
|---|---|---|
| `critical_alarm_local` (planned, shared with ADR-009) | No critical-alarm path in the architecture model passes through a cloud component | Planned |
| Offline tolerance (staging) | With the uplink cut, admission, critical alarms and telemetry buffering continue, and the backlog replays without loss | Not yet run; reported as SKIPPED until staging hardware exists |

## Changelog

- 12 September 2026: Accepted.
- 7 October 2026: Amended.
  - Critical alarms moved from cloud evaluation to the zone edge node (ADR-009). Cloud rules now cover advisory concerns only.
  - A2 now restricts LoRaWAN to advisory sensors. A4 now treats keeper rounds as a care procedure, not the alert bound.
  - Added the placement rule (device / estate edge / cloud) and edge AI inference (ADR-008).
  - Fixed the gate-network assumption reference (A1, previously cited as A2).
  - Added the Enforcement section.

## References

- Offline gate scanning pattern and its limits: https://terrapin.bigtickets.com/event-ticketing-platform/blog/ticket-scanning-gate-entry-guide/ ; https://ticket-generator.com/blog/event-ticket-scanner
- Manifest / idempotent push / delta pull API shape: https://dev.to/nasrulhazim/offline-first-check-in-a-laravel-api-that-survives-venue-wi-fi-36nl
- Edge MQTT offline buffering: https://docs.hivemq.com/hivemq-edge/mqtt-bridging.html ; https://www.emqx.com/en/products/emqx-edge
- LoRaWAN payload and duty-cycle limits: https://docs.aws.amazon.com/whitepapers/latest/implementing-lpwan-solutions-with-aws/lorawan.html ; https://www.actility.com/understanding-duty-cycle-lorawan/
