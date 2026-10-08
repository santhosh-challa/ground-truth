# ADR-009: Critical alarms are decided on the zone edge node, never in the cloud

**Status:** Accepted

**Date:** 7 October 2026

## Context

Some conditions on the estate harm an animal or a visitor within minutes or hours: a dissolved-oxygen collapse in an aquatic tank, a failed pump, a breached enclosure. The README's design rule is that no safety-critical (P0) decision may depend on the cloud, the Wi-Fi or a non-deterministic model.

Until now our documents disagreed about where these alarms are decided:

- README §8 puts Layer 1 trip logic and its siren and pager outputs on the zone edge node.
- [ADR-005](adr-005-deployment-topology.md) evaluated animal alert rules in the cloud and relied on keeper rounds every 2 hours during an outage.
- README §7.2 says keeper rounds do not bound automated alert delay.

These cannot all describe the same guarantee. This ADR settles it. It also separates three things that were previously treated as one:

| Class | Examples | Tolerable delay | Who decides |
|---|---|---|---|
| **Critical alarm** | Dissolved oxygen, water temperature, pump or flow failure, water level, enclosure or barrier breach, emergency-stop activation | Seconds | Deterministic rule on the edge node raises the alarm; people respond |
| **Advisory welfare concern** | Configured thresholds on non-critical readings, keeper observations | Hours | Keeper or vet reviews in the Animal application (cloud) |
| **AI evidence summary** | Summary of readings and notes attached to a concern | Can pause | Advisory only; never needed to raise or act on an alarm |

This ADR covers critical alarms only. Ride emergency stops halt the ride through the ride's own control circuit. This ADR covers raising and routing the alarm, not stopping the machine.

## Options

1. **Cloud-evaluated rules with keeper rounds as the outage control** (previous ADR-005 position). Rejected: during an uplink outage no critical alarm fires, and a tank can be lost well within a 2-hour round.
2. **Deterministic rules on the zone edge node, with power, watchdog and peer monitoring mitigations.** Chosen.
3. **Alarm independent of the edge node** (sensor → local controller or relay → siren; node only pages and logs). Strongest, but adds a controller per critical point and more devices for a small team to maintain. Revisit if measured node availability falls short (see Consequences).
4. **Paired active/standby edge nodes per critical zone.** Removes the node as a single point of failure, but doubles node cost in critical zones and adds failover complexity. Same revisit trigger as option 3.

## Decision

Critical alarms are evaluated by a **deterministic rule engine on the zone edge node** and sound locally. They do not depend on the cloud, the internet uplink or any AI model.

### Dependency path

```text
Critical sensor (wired or IP; not LoRaWAN)
      │
      ▼
Zone edge node: deterministic rule engine
      │
      ├──► Local siren / strobe in the zone
      ├──► Staff pagers via the estate radio/paging system
      └──► Copy of the alarm on the P0 lane to the cloud (for the record; not required for the alarm)
```

- **No model in the decision path.** AI camera detection (safety Layer 2) may raise its own advisory alerts. It never suppresses, delays or substitutes for a critical alarm.
- **Thresholds are data, not code.** Vets and the safety officer own the threshold values for each enclosure and zone. They are versioned and reviewed like code. This ADR does not set the values.
- **Critical sensors use wired or IP links.** LoRaWAN is used only for advisory readings, because of its duty-cycle limits and the extra hop through a radio gateway.
- **Critical alarms have no alert budget.** Alert budgets and precision-first tuning apply to advisory concerns only.
- **People hold authority.** Every lockdown, evacuation, gate closure and all-clear is a human decision (see [ADR-010](adr-010-ai-authority-by-risk.md)).

### Keeping the edge node from silently failing

The edge node is now a single point of failure for sounding a critical alarm. We accept that, with these mitigations:

| Mitigation | What it covers |
|---|---|
| **UPS** on the edge node, its network switch, critical sensors and the siren | Power cuts. The runtime target is set during hardware selection; the node announces low UPS before it shuts down |
| **Hardware watchdog** | Hung software. The node restarts automatically |
| **Peer heartbeat monitoring** | Node down. A neighbouring zone's edge node watches heartbeats over the estate LAN and pages staff through its own outputs. The cloud also watches Sparkplug B death certificates as a second observer |
| **Stale-reading and probe-disagreement alarms** | Sensor faults. A silent sensor is an alarm, not "no news". Critical tanks get redundant dissolved-oxygen probes |
| **Weekly siren and pager self-test** | Output failures |

### Operating restrictions

When a required control is unavailable, the affected zone operates under a restriction until it is restored:

| Failure | How it is detected | Restriction |
|---|---|---|
| Edge node down | Peer heartbeat loss; cloud death certificate | Manual checks of critical tanks and enclosures every 30 minutes; paid animal encounters paused; zone flagged on The Steward |
| Critical sensor stale or faulty | Stale-reading or disagreement alarm | Manual reading on that tank or enclosure every 30 minutes until replaced |
| Siren or pager fails self-test | Weekly self-test | Staffed presence in the zone during opening hours until repaired |
| UPS low or failed | Node announcement; peer monitoring | As for "edge node down" |
| Internet uplink down | Uplink monitor | **No restriction.** Alarms are unaffected; the cloud copy is delayed |

The 30-minute interval is an initial assumption for the vets and the safety officer to confirm.

### Assurance plan

We do not claim this design makes the estate licensable or insurable. We commit to an assurance plan:

1. **Hazard scenarios** for each critical alarm class, including each failure in the table above.
2. **Threshold ownership.** Vets and the safety officer sign off thresholds per enclosure before it opens.
3. **Proof tests.** Weekly siren and pager tests. A monthly drill that removes an edge node's power, measures detection and paging by the peer node, and confirms the restriction is applied.
4. **Acceptance before operation.** A zone opens only after its alarm path has passed a hardware test on site.

Evidence status today: **Designed.** Nothing in this ADR has yet been simulated or hardware-tested.

## Consequences

**Benefits.** Critical alarms keep working through any internet outage. Each alarm has one documented dependency path with a known failure response, and the three alarm classes no longer contradict each other across documents.

**Costs.**
- UPS units, watchdogs and wired critical sensors in every zone that has critical points.
- Peer monitoring configuration, plus weekly and monthly proof tests that take staff time.
- The node remains a single point of failure for the time between failure and detection, covered by the operating restriction.

**Revisit triggers.** Move to option 3 or 4 for a zone if any of these happens:
- measured edge-node availability during opening hours falls below the target set at hardware selection
- a critical alarm is missed because of a node failure
- an operating restriction is triggered more than an agreed number of times per quarter

## Enforcement

| Check | What it verifies | Evidence status |
|---|---|---|
| `critical_alarm_local` (architecture check, planned) | Every critical-alarm path in the declared architecture model uses only device and edge components and has no AI dependency. A path routed through a cloud component fails the build | Planned |
| Safety latency, < 2 s from detection to siren (staging hardware test) | Measured on a staging edge node with real sensors | Not yet run; reported as SKIPPED until staging hardware exists |
| Monthly node-failure drill | Peer detection, paging and the operating restriction | Not yet run |

## Changelog

- 7 October 2026: Proposed. Resolves the conflict between README §7.2, README §8 and ADR-005.
- 8 October 2026: Accepted.
