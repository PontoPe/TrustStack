# Roadmap to finished

The durable plan. Survives sessions; the agent's context does not.

**Seeded 2026-07-30 from verified repo state.** Every session that touches an item updates
this file and commits it. If this file and a repo disagree, the repo is right — re-verify
with `scripts/status.ps1` and fix this file.

Legend: `[ ]` open · `[~]` in progress · `[x]` done · `[-]` dropped, with a reason.

---

## Definition of finished

TrustStack is finished when **each of the four layers has all five**:

1. Code applied to real infrastructure
2. Real artefacts in `docs/evidence/` — command output, not prose
3. A demo GIF plus its `.cast`
4. A threat model whose residual risks are stated, not implied
5. The repository public

Nothing here requires zero open gaps. See "Not incompleteness" below.

## Current standing

| Layer | Code | Evidence | Demo | Public | Remaining |
|---|---|---|---|---|---|
| ProvenancePipeline | ✅ | ✅ | ✅ | ✅ | essentially none |
| KateClusters | ✅ | ✅ | in progress | ❌ | owner active: GIF, real CI run, go public |
| AwLZ | ✅ | partial | ❌ | ✅ | GuardDuty/CIS/cost evidence, T5/T8 |
| PontoAntiCrack | partial apply | ❌ | ❌ | ❌ | Lambda quota, finish apply, then B2–B8 |

Regenerate with `pwsh scripts/status.ps1 -Markdown`. Never type these numbers by hand.

---

## A. Cross-cutting — overlooker does these

- [x] **A1** AwLZ handbook rename finished and merged in
      [PR #8](https://github.com/PontoPe/AwLZ/pull/8); `main` is clean.
- [x] **A2** Empty `live/security/` and `live/workload-dev/` scaffolds removed in PR #8.
- [x] **A3** KateClusters' two pending commits and the reconciliation commit were pushed;
      `main` is clean and aligned with `origin/main`.
- [x] **A4** `docs/AwLZ-handbook.md` is the content-identical in-repo copy of the former
      Nextcloud handoff; SHA-256 equality was checked before merge.
- [x] **A5** KateClusters posture corrected: default-deny is **per namespace**, with no
      Calico `GlobalNetworkPolicy`, so a fresh namespace is fully open. README, architecture,
      NetworkPolicy docs and threat model now say so and record global default-deny as the
      closing condition. Verified by `make validate` at commit `242b5e1`.
- [x] **A6** Roadmap was stale: `AlwaysPullImages` was already accepted in KateClusters
      ADR-004 and referenced by `kubeadm-config.yaml`; README/threat model now expose its
      exact role and limit.
- [x] **A7** Propagated `demo-record.sh` to AwLZ, KateClusters and PontoAntiCrack with
      context-specific `DENY_PATTERNS`. Each script passed syntax,
      a context leak probe, and a safe negative control; all three are executable.
- [x] **A8** Contradiction sweep completed: tracked Markdown links pass in all four repos;
      Kate's pre-cluster status, NetworkPolicy scope and vmrun path were corrected;
      ProvenancePipeline's dead `policies/verify/` scaffold and references were removed;
      PAC's unavailable provider lock was refreshed from 6.57.0 to signed 6.57.1.
- [x] **A9** `TrustStack/README.md` reconciled from `scripts/status.ps1 -Markdown`:
      41/22/30/16 commits, 52 ADRs, ADR-005 inversion and active T9 stated.
- [x] **A10** Agent instructions are vendor-neutral in all four siblings: `AGENTS.md` is
      canonical and `CLAUDE.md` / `AGENT.md` are one-line pointers, with no duplicate copy.
      Repo-specific validations passed before commits. Pushed in AwLZ `c6002c4`,
      ProvenancePipeline `b04e72c`, KateClusters `242b5e1`, PontoAntiCrack `9ac2bfe`.

## B. PontoAntiCrack — the long pole

Nothing here can be done by the overlooker: it needs `aws sso login`, which needs a browser.
Prompts 08–10 are written and gated. Items stay open until the repo sessions produce real
AWS evidence.

- [~] **B1** `make build` → plan → apply with `dry_run = true`. Partial apply is stable:
      31 resources, three dry-run Lambdas, zero targets/taints. Blocked because the regional
      Lambda quota is 10; the technical requirement is 25 but official self-service accepts
      only a request of at least 1000. Details at PAC commit `86067a7`.
- [ ] **B2** `aws events test-event-pattern` on all three patterns. **Gate.** Three
      load-bearing assumptions die here; a `false` means that detection is dead regardless of
      the 167 tests. Nothing downstream proceeds until this passes.
- [ ] **B3** Capture real CloudTrail events, replace all 15 fixtures, flip the provenance
      markers, re-run the suite.
- [ ] **B4** Detonate with Stratus, `dry_run` still true. Assert alert + audit snapshot +
      resource unchanged.
- [ ] **B5** `dry_run = false`, lab account only, re-detonate, measure time-to-remediate.
- [ ] **B6** Trip the circuit breaker deliberately and watch it hold. A control never
      observed working is a comment.
- [ ] **B7** Evidence written, demo GIF recorded.
- [ ] **B8** Repo public.

Delegation: B1–B2 → `prompts/08-pac-apply-pattern-gate.md`; B3–B4 →
`prompts/09-pac-real-fixtures-and-dry-run.md`; B5–B8 →
`prompts/10-pac-live-remediation-demo-public.md`.

**Do not go past B4 into B5 without B3.** Live remediation with unconfirmed patterns is a
system that may not fire, or may fire on the wrong resource, holding write access to AWS.

## C. AwLZ — evidence, not code

Delegation: C1–C3 → `prompts/11-awlz-cost-and-cis-evidence.md`; C4–C5 →
`prompts/12-awlz-risk-controls-and-ci.md`; C6–C7 →
`prompts/13-awlz-demo-and-cost-actuals.md`.

- [x] **C1** GuardDuty enrollment closed. The management account had no regional detector,
      which is why delegated auto-enable could not reach it; the detector is Terraform-managed
      and all four members are `Enabled`.
- [x] **C2** Cost lever decided and applied. Five CIS subscriptions project USD 24.77/month
      jointly against a USD 20 ceiling, so CIS is retained in `awlz-security` only and
      future-account auto-enable is `NONE` — USD 13.73 projected, stated in `docs/cost.md`.
- [x] **C3** Control experiment run and reversed inside a 5m20s window on `awlz-lab` alone.
      The honest result is negative and is published as one: the CIS score is identical
      control by control with and without the SCPs, because no CIS v3.0.0 control reads an
      SCP. The behavioural probes are what show the guardrails working.
- [x] **C4** Permission boundaries, the Config rule and the `require-permissions-boundary`
      SCP are live in four accounts; the T8 alarm moved to `ALARM` on real recovery-role
      assumptions rather than a synthetic metric. Both residual risks in the threat model
      are rewritten to what is now true.
- [x] **C5** `awlz-gha-plan-readonly` exists per member account. All six stacks — including
      `live/logging`, `live/detection` and `live/ci-oidc` — plan green in CI through OIDC
      with no administrator anywhere.
- [ ] **C6** Cost actuals. Cost Explorer still returns `Estimated: true`; earliest defensible
      retry is **2026-08-02T12:00:00-03:00** for the 28 Jul–1 Aug window.
- [x] **C7** Demo recorded, audited as text and inspected as pixels: the plan role allowed on
      a Config read and explicitly denied on a Config write by its boundary.

## D. KateClusters — done

Delegation: D1–D3 → `prompts/14-kate-demo-ci-public.md`.

- [x] **D1** Deterministic demo recorded — `docs/img/demo.gif` and `demo.cast`.
- [x] **D2** CI green 5/5 on `main`, so kubescape and polaris are no longer unverified.
- [x] **D3** Repository public, 123/123 links valid, history rewritten and rescanned across
      38 commits with no secret detected. PR #1 merged; VM `kate` released.

## E. ProvenancePipeline — done, with one choice

- [x] CI, enforcement, evidence, demo, public.
- [ ] **E1** *Optional.* Close B5/T9: `actions/attest-build-provenance` writes the only bundle
      Kyverno can see, and the step is gated on the repo being public. Making the repo private
      again denies every new image at admission. Documented route: pin cosign 2.x, whose
      default is the legacy layout. Needs a CI change, a release, and re-verification.
      **Leaving it documented is a defensible choice.** Closing it is not required to finish.

---

## Not incompleteness — do not spend sessions here

Each of these is a **stated limit with the condition that would close it**. A security
portfolio with no open gaps reads as dishonest, because real systems have them.

- SLSA Build L2, not L3 — the provenance predicate is assembled in the job that builds.
- The mining-port Falco rule cannot fire when egress is already blocked.
- No T1098 detection; `sg-open` blind to `ModifySecurityGroupRules`.
- Falco not fully offline; no low-and-slow authz rule; no CPU-anomaly signal for T2.
- No Rekor monitoring.
- 40 CIS WARNs remain — "100%" means `PASS / (PASS + FAIL)`.
- Single node, no HA, no multi-tenant isolation claimed.

Prove what is built before closing any of these.

---

## Time-sensitive

| When | What |
|---|---|
| **~27 Aug 2026** | GuardDuty 30-day trial ends. The first invoice understates steady state. C2 must be decided before this |
| After every detonation | `stratus status` — a forgotten instance is ~USD 9/month against a USD 20 ceiling shared with AwLZ |
| Before a billing cycle closes | C6 cannot be done earlier |

## Current execution order

```text
PAC       paused at B1 quota decision; awlz-lab released
AwLZ      C1-C5 and C7 merged; only C6 open, blocked until 2026-08-02
Kate      D1-D3 complete and public; VM kate released
Provenance VM phase unblocked
```

Owners are persistent; estimates are no longer session counts. The overlooker advances the
next unblocked owner and reconciles this roadmap after every owner result.

## Autonomous owner entrypoints

For one persistent agent per repository, use these instead of manually passing the
phase prompts:

| Repository | Owner prompt | Scope |
|---|---|---|
| TrustStack | `prompts/19-autonomous-overlooker.md` | Coordinate owners, leases, reporting and the minimal operator-intervention budget |
| PontoAntiCrack | `prompts/15-pac-autonomous-owner.md` | B1–B8, including bounded lab detonation, remediation, demo and publication |
| AwLZ | `prompts/16-awlz-autonomous-owner.md` | C1–C7, with a deterministic USD 20 cost rule and lab-only SCP experiment |
| KateClusters | `prompts/17-kate-autonomous-owner.md` | D1–D3, including snapshot/recovery, demo, CI and publication |
| ProvenancePipeline | `prompts/18-provenance-autonomous-owner.md` | Preserve the finished state; attempt B5/T9 without weakening admission |

The prompts are resumable through each repo's `docs/PROGRESS.md`. They authorize routine
actions only inside the named repo and environment; their stop conditions remain the
security boundary.
