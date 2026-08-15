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
| ProvenancePipeline | ✅ | ✅ | ✅ | ✅ | none; E1 is optional |
| KateClusters | ✅ | ✅ | ✅ | ✅ | none |
| AwLZ | ✅ | ✅ | ✅ | ✅ | none |
| PontoAntiCrack | ✅ | ✅ | ✅ | ✅ | none; two of three techniques undetonated |

**All four layers meet the definition of finished, and C6 closed on 2026-08-04.** Nothing
in the program is open on a deadline; what remains is optional work and the maintenance
below.

Regenerate with `pwsh scripts/status.ps1 -Markdown`. Never type these numbers by hand.

---

## A. Cross-cutting — overlooker does these

- [x] **A11** PontoAntiCrack CI repaired. `check-detection-coverage.sh` and
      `build-lambda.sh` were mode 644, so every run exited 126 before a gate executed, and
      `aquasecurity/trivy-action@0.28.0` no longer resolved. Both fixed at PAC `e796ecf`,
      which is the first green run in that repository. `make patterns` was added so the B2
      gate is one command.

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

## B. PontoAntiCrack — done

Closed on 2026-07-30, from the quota request through to publication.

- [x] **B1** Applied with `dry_run = true`. The regional Lambda concurrency quota was
      raised from 10 to 1000 — the lowest value Service Quotas accepts — and the deferred
      wiring then applied cleanly: 12 creates, 3 updates, no drift.
- [x] **B2** `make patterns`: seventeen fixtures, zero disagreements with EventBridge. Run
      first against documentation-derived fixtures and again against captured ones.
- [x] **B3** Fifteen of seventeen fixtures are recorded events. The assumption flagged as
      highest-risk held — CloudTrail emits `DeleteBucketPublicAccessBlock` — and real events
      corrected five assumptions the tests around the patterns had encoded.
- [x] **B4** `sg-open` detonated with Stratus Red Team v2.34.1 under `dry_run = true`: full
      snapshot recorded, port 22 still open afterwards. Dry run means dry run.
- [x] **B5** Live remediation revoked the world-open SSH rule **5.97 s** after the
      attacker's API call and left the group's port 443 rule alone.
- [x] **B6** Circuit breaker tripped on purpose: seven world-open ports in eighty seconds,
      five actions allowed, four `BLOCKED` records, four ports deliberately left open.
- [x] **B7** Evidence written — pattern gate, fixture capture, detonation write-up,
      time-to-remediate — and the demo recorded with its cast.
- [x] **B8** Repository public. History was scrubbed of the lab account ID first.

**What detonating found that nothing else did.** Two defects survived 176 green tests, a
pattern gate agreeing with EventBridge on every fixture, and fixtures captured from real
CloudTrail. The loop guard tested the whole principal ARN, which contains the
caller-chosen session name, so any attacker passing `--role-session-name pac-…` was
skipped with a confident `SKIPPED`. And `AuthorizeSecurityGroupIngress` has two CloudTrail
encodings — every fixture had been produced by the AWS CLI, so an attacker using the
legacy top-level parameters was invisible. Both are fixed and written up in
`docs/evidence/detonation-sg-open.md`.

Still undetonated: `s3-public` and `iam-key-leak`, so their remediation latency is
unmeasured and no number for them is claimed.

Delegation: B1–B2 → `prompts/08-pac-apply-pattern-gate.md`; B3–B4 →
`prompts/09-pac-real-fixtures-and-dry-run.md`; B5–B8 →
`prompts/10-pac-live-remediation-demo-public.md`.

That ordering held in practice, and the reason it exists showed up exactly where it was
predicted: B3 and B4 caught two defects that would have made B5 a live remediation running
on a pattern that did not match the attack.

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
- [x] **C6** Cost actuals measured 2026-08-04 against the closed July window
      (`Estimated: false`). Gross usage USD 1.4830, fully covered by credits, so the invoice
      was zero — reported as gross because the net would understate the model by its whole
      subject. August run rate USD 6.38/month against the USD 20 ceiling. Trials end in late
      August, so **September is the first representative month**.
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

## Maintenance — what goes stale, where, and what refreshes it

Three kinds of staleness. Only the first has dates.

### 1. Clock-driven

| When | What | Where | How to refresh |
|---|---|---|---|
| ~**27 Aug 2026** | GuardDuty's 30-day trial ends, and Security Hub's with it. Every cost figure before that date understates steady state | `AwLZ/docs/cost.md`, `AwLZ/README.md`, `TrustStack/README.md` | Nothing to do on the day; it only sets when the next measurement is meaningful |
| **on/after 1 Sep 2026** | **September is the first representative month** — first with no credits *and* no trials. Re-run the closed-window query | `AwLZ/docs/cost.md` | The `get-cost-and-usage` command in that file, **with the `RECORD_TYPE` filter**; without it credits net usage to zero |
| Each closed billing window | The run rate drifts as resources come and go | `AwLZ/docs/cost.md` | Same query; compare against the recorded delta table |
| Whenever the CIS score is quoted | `cis-score.txt` is a timestamped snapshot, not a live value | `AwLZ/docs/evidence/cis-score.txt` | `make evidence` in AwLZ |
| After any detonation | A forgotten Stratus instance is ~USD 9/month against a USD 20 ceiling | the lab account | `stratus status` — every technique must read `COLD` |

### 2. Condition-driven

No date; a change invalidates them. The authoritative list is
[threat-model.md §9](threat-model.md#9-revisit-conditions): a fifth repository or any new
coupling, a second operator, a new KateClusters namespace, either repository's visibility
changing, the release workflow gaining an approval gate, or retention changing on either
side of the audit/evidence boundary.

Two more outside that model:

| Condition | What it invalidates | Where |
|---|---|---|
| PontoAntiCrack's lab is left with `dry_run = false` | The lab remediates for real, continuously. That is the state the 5.97 s measurement was taken in, and it is deliberate — but it is a standing decision, not a fact | `PontoAntiCrack/docs/PROGRESS.md`; the value lives in the gitignored `infra/terraform.tfvars` |
| A detection's behaviour changes | The recorded demo replays committed evidence and will keep showing the old behaviour happily | `*/docs/img/demo.gif` and `.cast`; re-record with each repo's `demo-record.sh` |

### 3. Drift-driven

Nothing breaks; the documents quietly stop describing the code.

| What | Where | How to refresh |
|---|---|---|
| Commit counts, ADR counts, test counts, evidence counts | `TrustStack/README.md` §2, `docs/HANDBOOK.md` §3, each repo's handoff | `pwsh scripts/status.ps1`, and re-derive counts from the filesystem rather than from memory |
| Pinned tool versions — terraform, tflint, trivy, checkov, aws-cli, cosign, Stratus, `agg`, asciinema | each repo's `docs/toolchain.md` or handbook | Bump deliberately; the pin is the point, so a bump is a decision and not housekeeping |
| Pinned AWS provider version and lock files | `*/live/*/.terraform.lock.hcl`, `PontoAntiCrack/infra` | `terraform init -upgrade`; a provider version disappearing from the registry has happened here once already |
| Third-party GitHub Action SHAs | every `.github/workflows/ci.yml` | Bump for security fixes. A tag would auto-update and that is exactly what the pin prevents |
| Base image digests | `ProvenancePipeline/build/` | Digest-pinned means static: a new CVE against a shipped image surfaces only on rebuild. There is no scheduled re-scan, and that gap is declared |
| `kube-bench` results and the CIS delta | `KateClusters/docs/cis-results.md` | Re-run after any cluster or Kubernetes version change |

### What needs an AWS session

Everything in §1 except the demo re-record. `aws sso login --profile mgmt`; sessions last
twelve hours and should be ended with an explicit logout.

## Current execution order

```text
PAC       B1-B8 complete and public; two of three techniques still undetonated
AwLZ      C1-C7 complete; cost is a measured actual, not a projection
Kate      D1-D3 complete and public; VM kate released
Provenance complete; E1 optional and not required to finish
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
