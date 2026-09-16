# ADR-005: Cloud primary deployment with local admission validation

**Status:** Accepted

**Created:** 12 September 2026

## Context

The selected use cases are animal health monitoring, footfall/popularity, and ticketing. Wi-Fi on the estate is patchy. The brief permits cloud services and provides a budget for MQTT-capable devices.
[ADR-001](001-adr-record-durability-and-sync.md) decides that every record is saved at its origin and forwarded when connected. That preserves records but cannot act on them during an outage. This ADR decides which functions run in the cloud, which run on the estate, and which run on the device itself, and why.


## Constraints from organizers

- Cost trade offs are expected at a high level: upfront spend versus ongoing spend that can be stopped.
- Historical data exists only as paperwork and staff experience.
- Device type assumptions are permitted if documented.

## Assumptions

- **A1. A dedicated gate network exists** (wired or a dedicated access point) that is more reliable than the estate's internet uplink. If false, the admission coordinator is no more available than the scanners' own caches and should be dropped.
- **A2. Sensors use LoRaWAN. Counters, cameras and scanners use IP** (Ethernet or suitable Wi-Fi). LoRaWAN payloads are small and regionally duty cycle limited, which suits periodic readings and may need validation for images or video support.
- **A3. The budgeted MQTT devices are sensors, counters and gateways**. 
- **A4. Keepers round every enclosure at least every 2 hours.** This is the alert tolerance.

## Decision

The application runs in the cloud. Two functions run on the estate because they must work while the internet uplink is down. Admission at the gates, and buffering of device telemetry. Everything else is either cloud-hosted or device-local.

### What runs where

| Function | Placement | Reason |
|---|---|---|
| Online ticket purchase, payment, issuance | Cloud (ticketing service + hosted payment provider) | Payment providers are cloud hosted. The public buys before arriving. |
| **Admission validation** | Gate scanners + **local admission coordinator** on the gate network | Must work during a WAN outage. Scanners hold a downloaded manifest (valid tickets, family-pass counts, revocations). The coordinator holds the shared admission log so gates agree on what is already used, which matters most for family-pass counts. If a scanner cannot reach the coordinator, it validates from its own cache and accepts a known duplicate window. That ticket group is routed to one designated scanner. Duplicates are visible on resync but cannot be undone. |
| **Walk-up sales** | Staffed lane, cash only | Ticket issued at the gate with a stable ID, admitted, registered with the coordinator, synced under ADR-001. The cloud ticketing service accepts gate issued tickets as a distinct origin. End of day control: cash taken reconciles to gate issued tickets. Card store and forward (deferred authorization) is deferred as a later option. |
| Sensor readings (enclosure, aquatic) | Sensor → LoRaWAN gateway → **edge MQTT broker with offline buffer** → cloud | The broker is the single estate to cloud path for device telemetry. It persists messages to disk while the uplink is down and publishes when it returns. Candidates: HiveMQ Edge, EMQX Edge. Either is replaceable by the other. |
| Animal alert rules | Cloud evaluated | During an outage no automated alert fires. Keeper rounds every 2 hours are the control, so an alert is delayed by at most one round. The "age of oldest unsent record" metric from ADR-001 is shown to staff so they know when automated alerting is blind.|
| Keeper/vet notes and observations | Tablet, synced direct to cloud | Second path to cloud, deliberately bypassing the broker. Tablets already have storage and an HTTP client, and notes carry attachments the broker path is not for. |
| Footfall counting | On the counter or camera | Only counts leave the device. Video never leaves the estate except selected clips retained locally for count validation. |
| Footfall reports and forecasts | Cloud | Historical analysis tolerates delay. Reports show input freshness per ADR-001. |
| Animal records, shared history, reporting | Cloud | One place to change behaviour and keep long term records. |
| AI gateway (extraction, summaries, planning assistance) | Cloud | Assistance can pause during outages. Provider swap and verification are covered in the AI ADRs. |

Two paths reach the cloud: broker-buffered telemetry, and direct device sync (tablets, scanners, staffed lane). Both obey ADR-001.

## Consequences

**Benefits:** most operational change happens in one place. Recording, admission and cash sales continue through an uplink outage. The MQTT device budget is exercised through a standard, replaceable component rather than bespoke buffering. Owning the ticketing service keeps gate issued tickets and online tickets in one model.

**Costs:** the coordinator and broker are two estate hosts that need power, patching, backup and a restart procedure. Cloud history and AI assistance are unavailable during outages and local copies go stale. Automated animal alerting is absent during outages. Safety rests on 2 hourly keeper rounds for that window. Offline broker buffering may be a licensed feature depending on the product chosen. Treat it as stoppable opex. The gate network (A2) is a single point of failure for coordinated admission. 

## Alternatives considered

| Alternative | Capex | Stoppable opex | Availability during WAN outage | Ops burden on estate | Verdict |
|---|---|---|---|---|---|
| **Chosen: cloud-primary, coordinator + edge broker** | Med | Med | Recording, admission, cash sales continue. Alerts and AI pause | Low–Med (two hosts) | Accepted |
| Cloud only, device caches, no estate hosts | Low | Low | Recording continues. Admission per scanner only, cross gate duplicates until resync | Lowest | Rejected for family passes. Revisit if single gate |
| Cloud-primary plus second internet link (cellular backup) | Med | Med–High (recurring carrier) | Higher, but dual carrier and power failures still occur | Low | Complementary, not a substitute. Keep the outage procedure regardless |
| Most services on the estate | High | Low | Highest | High (hosting, DB, backup, remote access) | Rejected| 
| Full application in both places | Highest | High | Highest | Highest (state reconciliation) | Rejected |

## References

- Offline gate scanning pattern and its limits: https://terrapin.bigtickets.com/event-ticketing-platform/blog/ticket-scanning-gate-entry-guide/ ; https://ticket-generator.com/blog/event-ticket-scanner
- Manifest / idempotent push / delta pull API shape: https://dev.to/nasrulhazim/offline-first-check-in-a-laravel-api-that-survives-venue-wi-fi-36nl
- Edge MQTT offline buffering: https://docs.hivemq.com/hivemq-edge/mqtt-bridging.html ; https://www.emqx.com/en/products/emqx-edge
- LoRaWAN payload and duty-cycle limits: https://docs.aws.amazon.com/whitepapers/latest/implementing-lpwan-solutions-with-aws/lorawan.html ; https://www.actility.com/understanding-duty-cycle-lorawan/
