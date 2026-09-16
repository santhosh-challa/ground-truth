# Platform Topology

# **Context**

The Von Digitalis estate has three naturally distinct visitor-facing areas: an adventure park (40 rides), a zoo & aquarium (200+ animals across 55 enclosures, including the jumping-piranha collection), and gardens (including the carnivorous-plant collection). Each area has genuinely different physical assets, sensor types, AI models, and alert thresholds.

At the same time, the estate must feel like one destination to visitors, and the Countess’s single sharpest question — which parts of the estate are most popular, so she knows where to invest and staff — is inherently a cross-area question. We must also respect the stated constraints: patchy WiFi, a fixed budget for MQTT-capable hardware, and a target of scaling from \~5,000 to 15,000 visitors/day within three years.

The decision: how do we structure the estate’s systems across these three areas?

# **Decision drivers**

* Visitors should experience one estate — one ticket, one app — not three disconnected products.

* Cross-estate popularity comparison must be a first-class capability, not an integration afterthought.

* The hardware/MQTT budget is finite and should be amortized, not tripled.

* Each area’s sensing and AI genuinely differ and must be tunable independently (e.g. welfare tunes to avoid false alarms; safety tunes to over-alert).

* New areas may open later; adding one should be cheap.

* The brief explicitly scores whether new additions match the existing architecture.

# **Options considered**

**Option A — Three separate per-domain platforms:** Each area gets its own end-to-end stack including its own ticketing, ingestion, and AI. Maximum domain autonomy, but triples shared plumbing, fragments the visitor journey, and makes cross-estate analytics an afterthought.

**Option B — One unified monolith:** A single system with one schema and one set of thresholds spanning all areas. Cheapest to stand up, but a leaky abstraction: a piranha tank, a Ferris wheel, and a greenhouse do not share data shapes or failure modes, so it satisfies none of them well and accumulates change risk.

**Option C — Shared horizontal platform with vertical domain modules (CHOSEN):** One platform backbone (ticketing, payments, identity, MQTT \+ edge ingestion, footfall/analytics, alerting, data lake, and the AI abstraction/eval layer) shared by all three areas, with per-domain modules owning their own sensors, AI models, and thresholds. Segregation is logical (via an MQTT topic hierarchy estate/{domain}/{asset}/{signal}), not physical.

# **Decision**

We adopt Option C: a shared horizontal platform with vertical domain modules. We standardize everything that benefits from consistency (identity, ticketing, ingestion pattern, alerting, analytics, AI governance) and differentiate only at the sensor and model layer, where the domains genuinely diverge. The estate is presented to visitors and judges as "one platform, three experiences."

# **Topology Map**

![AltText](../assets/platform-topology-diagram.png)

# **Options comparison**

Each row is a decision driver; the chosen option is weighed against the rejected alternatives.

| DIMENSION | Chosen: Platform \+ domain modules | Rejected alternatives |
| :---- | :---- | :---- |
| **Visitor experience** | One ticket, one app, one estate — seamless. | Per-domain platforms: 3 tickets / apps, fragmented journey. |
| **Cross-estate insight** | Native — compare popularity across all domains (the Countess’s sharpest ask). | Per-domain: cross-domain comparison is a painful afterthought. |
| **Build cost** | Ticketing, MQTT, AI layer built once, amortized 3×. | Per-domain: rebuild shared plumbing 3×. Monolith: cheap but leaky. |
| **Domain fit** | Sensors, models, thresholds tuned per domain. | Unified monolith: one schema/threshold fits none well. |
| **Scalability** | New domain (e.g. hedge maze) plugs into existing backbone. | Per-domain: greenfield each time. Monolith: change risk grows. |
| **Architectural fit** | A consistent backbone IS the fit story the brief asks for. | Both alternatives weaken the "additions match existing arch" case. |

# **Consequences**

**Positive**

* One ticket / one app; a coherent visitor experience that supports the growth and retention goals.

* Cross-estate popularity analytics for free — directly answers the Countess’s sharpest ask.

* The MQTT/edge and AI investment is built once and amortized across all three areas, respecting the budget constraint.

* Adding a future area is a plug-in, not a greenfield build — a clean scalability story.

* A consistent backbone is itself the "additions match the existing architecture" answer the judges want.

**Negative / trade-offs**

* The shared platform is a potential single point of failure and a coordination bottleneck; it needs clear ownership (a platform team) and strong SLAs.

* Requires discipline to keep the platform/domain boundary clean — the failure mode is domain-specific logic leaking into the shared platform, or domains bypassing platform services.

* Governance overhead: domains must agree on shared contracts (topic schema, alert severity model) up front.

**Mitigations**

* Enforce the boundary via the MQTT topic hierarchy and platform-as-a-product ownership; domains consume services, they don’t reinvent them.

* Keep safety-critical alerting able to run at the domain edge even if the central platform is degraded.

