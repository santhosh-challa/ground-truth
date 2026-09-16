# Architecture Fitness Functions

These fitness functions make the key architecture characteristics measurable and testable through CI/CD and operational validation.

## Offline Tolerance

**Target:**

The estate should continue operating for at least 4 hours without a cloud connection. Ticketing, visitor counting, and safety functions must continue locally, and the backlog must replay without data loss after connectivity is restored.

**Test:**

In the staging environment, a chaos test severs the zone node uplink to the cloud. The test verifies ticketing, visitor counting, safety trips, local data retention, and backlog replay.

**Build Failure:**

Fail the build if ticketing, counting, or safety operations stop, or if backlog replay results in data loss or inconsistency.

## Safety Latency

**Target:**

Safety event detection to on-site alarm must remain below 2 seconds at the edge.

**Test:**

Inject a synthetic safety trip nightly for each zone node and measure detection-to-alarm latency.

**Build Failure:**

Fail if the measured latency is 2 seconds or greater.

## Elasticity

**Target:**

The system must support 3x visitor growth without rearchitecture.

**Test:**

Run load tests for entry, application traffic, and telemetry at 3x peak load. Measure p95 latency and cost per visitor.

**Build Failure:**

Fail if p95 latency or cost per visitor exceeds the agreed envelope.

## Provider Portability

**Target:**

A Tier B/C provider should be replaceable within one working day using configuration changes rather than application rearchitecture.

**Test:**

Run weekly contract tests against a second provider.

**Build Failure:**

Fail if the secondary provider does not satisfy the defined integration contract.

## Verifiability

**Target:**

Every AI decision must be traceable to its input data, model version, and prompt version.

**Test:**

An audit sampler reconstructs the lineage of selected AI decisions.

**Build Failure:**

Fail if any sampled AI decision cannot be reconstructed from the recorded lineage.

## Cost Predictability

**Target:**

AI inference spending must remain bounded and gateway budget caps must be enforced.

**Test:**

Validate gateway budget caps and generate a nightly cost-variance report.

**Build Failure:**

Fail if budget caps are not enforced or cost variance exceeds the agreed threshold.

## Privacy

**Target:**

The system must not perform biometric identification. Imagery should remain at the edge except when required for an incident.

**Test:**

Run static scanning for face-recognition APIs and an egress test for restricted imagery.

**Build Failure:**

Fail if a prohibited biometric/face-recognition API is detected or restricted imagery leaves the edge.

---

# Fitness Functions in CI/CD

Architecture fitness functions are automated as part of the CI/CD process so that architecture characteristics are continuously validated instead of being checked manually.

## CI/CD Execution Flow

```text
Developer Commit / Pull Request
            |
            v
   GitHub Actions Workflow
            |
            +----------------------+
            | Fitness Functions    |
            +----------------------+
            |
            +--> Offline Tolerance
            +--> Safety Latency
            +--> Elasticity
            +--> Provider Portability
            +--> Verifiability
            +--> Cost Predictability
            +--> Privacy
            |
            v
       Build Result
       /          \
    PASS          FAIL
     |              |
     v              v
 Continue       Stop / Block
 Pipeline       Promotion
```

The workflow is defined in:

`/.github/workflows/fitness-functions.yml`

The executable fitness-function tests are maintained under:

`/engineering-practices/fitness-tests/`

## Pipeline Stages

| Pipeline Stage | Fitness Function / Test | Where It Runs | Trigger / Frequency | Build Failure Condition |
|---|---|---|---|---|
| PR / CI | Offline Tolerance | GitHub Actions + staging chaos test | PR / Push | Offline operation below 4 hours or chaos test fails |
| PR / CI | Safety Latency | GitHub Actions + staging measurements | Nightly | Detection-to-alarm latency is 2 seconds or greater |
| PR / CI | Elasticity | Staging load-test environment | Load-test execution | System cannot handle 3x peak or p95/cost exceeds envelope |
| PR / CI | Provider Portability | CI contract-test environment | Weekly | Secondary provider contract test fails |
| PR / CI | Verifiability | CI + production audit sampling | CI / Random production sampling | AI decision lineage cannot be reconstructed |
| PR / CI | Cost Predictability | CI + runtime gateway controls | Nightly variance check | Budget cap is not enforced or cost variance exceeds threshold |
| PR / CI | Privacy | CI static scan + egress test environment | PR / Push | Biometric API detected or restricted imagery leaves the edge |
| Staging | Chaos Testing | Staging zone node | During staging validation | Ticketing, counting, safety, or backlog replay fails |
| Nightly | Safety & Cost Validation | Staging / operational validation | Nightly | Safety latency or cost variance violates target |
| Weekly | Provider Contract Testing | CI contract-test environment | Weekly | Provider capability contract fails |

## Where Chaos Tests Execute

The offline-tolerance chaos test is intended to execute in the staging environment.

The test deliberately severs the cloud uplink of a zone node and verifies that:

1. Ticket validation continues locally.
2. Footfall/counting continues locally.
3. Safety trips continue to operate.
4. Locally queued data is retained.
5. The backlog is replayed after connectivity is restored.
6. No data is lost during the outage.

The required offline operating window is at least four hours, while safety functionality must remain unaffected by cloud connectivity loss.

## What Fails a Build?

A fitness-function job returns a non-zero exit code when its required architectural constraint is violated.

Examples:

- Offline tolerance below 4 hours -> build fails.
- Zone-node offline/chaos test fails -> build fails.
- Safety latency reaches or exceeds 2 seconds -> build fails.
- Tested elasticity is below 3x -> build fails.
- Secondary provider contract test fails -> build fails.
- Required AI lineage information is missing -> build fails.
- Gateway budget cap is not enforced -> build fails.
- Cost variance is outside the configured threshold -> build fails.
- Face-recognition/biometric API is detected -> build fails.
- Restricted imagery egress is detected -> build fails.

A failed fitness-function job prevents the pipeline from being considered successful and therefore prevents the affected change from being promoted.

## Current GitHub Actions Workflow

The current workflow runs all seven fitness functions independently. This makes the failure visible at the individual architecture-characteristic level instead of having one combined test hide which requirement failed.

```text
GitHub Actions
|
+-- Offline Tolerance       PASS
+-- Safety Latency          PASS
+-- Elasticity              PASS
+-- Provider Portability    PASS
+-- Verifiability           PASS
+-- Cost Predictability     PASS
+-- Privacy                 PASS
|
+-- Overall Workflow        PASS
```

## Local Execution

Each test can also be executed locally before pushing:

```bash
./engineering-practices/fitness-tests/offline-tolerance.sh
./engineering-practices/fitness-tests/safety-latency.sh
./engineering-practices/fitness-tests/elasticity.sh
./engineering-practices/fitness-tests/provider-portability.sh
./engineering-practices/fitness-tests/verifiability.sh
./engineering-practices/fitness-tests/cost-predictability.sh
./engineering-practices/fitness-tests/privacy.sh
```

The same scripts are executed by GitHub Actions, providing a consistent validation path between local development and CI.
