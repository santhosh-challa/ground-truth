# **ADR-006: Ticketing, Pass & Entry  Architecture**

**Date:** 2026-09-14  
 **Status:** Accepted

## **Context**

Von Digitalis Estates requires a ticketing system supporting two sales channels:

1. **Online Booking** — visitors purchase tickets/passes through web/mobile.  
2. **Counter POS** — walk-in visitors purchase tickets/passes at the estate.

Both channels must use the same ticketing rules and create consistent visitor and transaction records.

The system must support:

* Park-wide ticket covering **Rides \+ Zoo \+ Aquarium**  
* Single-area tickets  
* Family passes  
* Ticket/pass pricing  
* Area-wise visitor capacity  
* Ticket validity  
* QR-based credentials  
* Redemption rules  
* Visitor check-in  
* Area-specific access/wristbands

Because connectivity across the estate can be unreliable, gate validation must also support **offline operation**.

# **Alternatives**

### **Option 1 — Centralized Ticket & Pass Rules (Chosen)**

Use a dedicated **Ticket Service** as the owner of all ticket/pass business rules.

```
Online Booking ──┐
                 ├──> Ticket Service
Counter POS ─────┘
```

Ticket Service manages:

* Ticket/pass type  
* Price  
* Availability  
* Capacity  
* Validity  
* Area entitlement  
* QR credential  
* Redemption rules

### **Option 2 — Ticket Rules in Each Channel (Rejected)**

Online Booking, Counter POS and Gate Validator independently maintain ticket rules.

**Problem:**

* Duplicate business logic  
* Pricing inconsistencies  
* Different validity rules  
* Difficult pass management  
* Difficult reconciliation

# 

# 

# **PrOACT**

| Requirement | Centralized Ticket Service | Distributed Rules |
| :---- | ----- | ----- |
| Online \+ Counter consistency | **High** | Low |
| Pricing management | **Centralized** | Duplicated |
| Capacity control | **Centralized** | Complex |
| Pass management | **Centralized** | Duplicated |
| QR generation | **Centralized** | Multiple implementations |
| Redemption rules | **Centralized** | Risk of inconsistency |
| Maintainability | **High** | Low |
| Offline gate support | Requires local validation | Easier but duplicates rules |

---

# **Decision**

We will implement **four core services with clear aggregate ownership**.

### **1\. User Service**

Owns:

* **User**  
* **User Profile**

It stores visitor information generated through both online and counter ticketing.

The information can subsequently support customer communication and future offers.

---

### **2\. Ticket Service**

Owns:

* **Ticket**  
* **Family Pass**

It is the **source of truth for ticket/pass entitlement**.

It manages:

```
Ticket / Pass
 ├── Type
 ├── Price
 ├── Validity
 ├── Capacity / Availability
 ├── Area Entitlement
 ├── QR Credential
 └── Redemption Rules
```

Examples:

```
Park-wide Ticket
→ Rides + Zoo + Aquarium

Zoo Ticket
→ Zoo only

Aquarium Ticket
→ Aquarium only

Family Pass
→ Configured family entitlement
```

Capacity rules will control whether additional visitors can be booked for a particular date/area.

### 

### **3\. Payment Service**

Owns:

* **Payment**

Responsibilities:

* Create payment transaction  
* Integrate with payment gateway  
* Maintain payment status  
* Handle payment confirmation  
* Handle failed/refunded transactions  
* Maintain gateway reference

The Payment Service does **not** own ticket entitlement.

---

### **4\. Visit Service**

Owns:

* **Visit**

Responsibilities:

* Store scheduled visit  
* Associate visitor with ticket/pass  
* Record actual entry  
* Record gate check-in  
* Record entry timestamp  
* Maintain ticket/pass utilization

This allows the system to compare:

```
Tickets / Passes Sold
        vs
Actual Visitors Entered
```

---

# **Entry Decision**

The **Gate Validator** is responsible for enforcing the ticket's entitlement at the physical entry point.

```
QR Scan
   ↓
Gate Validator
   ↓
Validate QR
   ↓
Validate Ticket / Pass
   ↓
Validate Validity
   ↓
Validate Area Entitlement
   ↓
Check Redemption Rule
   ↓
       ┌───────────────┐
       │ Valid         │ Invalid
       ↓               ↓
    Allow Entry       Reject
       ↓
Record Check-in
       ↓
Issue Area Wristband
```

The wristband/access identifier represents the entitlement but **does not become the source of truth**.

---

# **Offline Entry**

Due to unreliable Wi-Fi, the Gate Validator will not depend exclusively on a live cloud request.

### **Connected**

```
QR
 ↓
Gate Validator
 ↓
Ticket / Visit Validation
 ↓
Visit Check-in
 ↓
Access
```

### **Connectivity Lost**

```
QR
 ↓
Gate Validator
 ↓
Local Validation Data
 ↓
Access Decision
 ↓
Local Entry Event
 ↓
Connectivity Restored
 ↓
Sync → Visit Service
```

The exact offline cache duration and conflict/replay policy must be defined during implementation.

---

# **Data Ownership**

| Aggregate | Service | Database |
| ----- | ----- | ----- |
| User | User Service | User DB |
| User Profile | User Service | User DB |
| Ticket | Ticket Service | Ticket DB |
| Family Pass | Ticket Service | Ticket DB |
| Payment | Payment Service | Payment DB |
| Visit | Visit Service | Visit DB |

**No service directly updates another service's database.**

---

# **Communication Strategy**

Use **synchronous APIs for transactional operations**:

```
Booking
Payment
Ticket Creation
User Operations
```

Use **asynchronous events/MQTT for edge and downstream events**:

```
Gate Check-in
Ticket Status Events
Device Status
Analytics Events
```

Example:

```
estate/gates/{gateId}/check-in
estate/ticketing/{ticketId}/status
```

---

# **Trade-offs & Mitigations**

| Trade-off | Mitigation |
| ----- | ----- |
| Ticket Service is business-critical | HA \+ horizontal scaling |
| Offline gate may have stale data | Controlled cache validity \+ synchronization |
| QR can be copied | Signed credential \+ redemption tracking |
| Duplicate offline redemption | Unique event ID \+ reconciliation |
| Payment and ticket state can diverge | Idempotency \+ payment webhook reconciliation |
| Async events are eventually consistent | Retry \+ idempotent consumers |

