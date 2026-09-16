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

