# TrustStack

Portfolio summary. Written 2026-07-30, cost section re-measured 2026-08-04 against the first
closed billing window. Every number below was read out of a repo or a command, not carried
over from a previous document.

Four repositories, one thesis. Owner: Pedro (GitHub `PontoPe`).

**The long-form account is [docs/HANDBOOK.md](docs/HANDBOOK.md)**: how the layers couple,
what proving each one actually found, where the method runs out, and what is open on
purpose. This file is the short version.

---

## 1. The thesis

Each repo builds a layer of trust in a system, and each one **proves its own claims rather
than asserting them**.

| Layer | Question it answers | Repo |
|---|---|---|
| Cloud governance | Can an account do something nobody watches? | **AwLZ** |
| Artifact provenance | Do I know where this container came from? | **ProvenancePipeline** |
| Runtime | If something breaks in, does anyone find out? | **KateClusters** |
| Response | When something is found, what happens automatically? | **PontoAntiCrack** |

The unifying rule, and the reason this reads differently from a tutorial portfolio:

> **The deliverable is not working infrastructure. It is reproducible infrastructure plus
> evidence that the controls do what the documentation claims — including where they don't.**

Every repo has a `docs/evidence/` directory and all four now hold real artefacts. The fourth
stayed empty **on purpose** until something had actually been measured there — filling it by
hand would have discredited the other three.

## 2. Status

| | Commits | Repo | Code | Proven against reality | Evidence |
|---|---:|---|---|---|---|
| **AwLZ** | 73 | public | 6 stacks applied to a live AWS org | ✅ SCPs probed, org trail delivering, 5 Config recorders, lab control experiment, break-glass alarm fired, **first closed-window cost actual** | 5 verification docs + GIF |
| **ProvenancePipeline** | 25 | public | CI + admission enforcement | ✅ signed image, attestations, Rekor, **4-case admission demo recorded** | 2 generated docs + GIF |
| **KateClusters** | 44 | public | cluster built + hardened; released | ✅ CIS 12 FAIL → 0, 4 attack sims with real alerts, CI green 5/5 | 2 kube-bench JSONs + GIF |
| **PontoAntiCrack** | 41 | public | 3 detections, 185 tests; deployed and detonated | ✅ remediation measured at 5.97 s, circuit breaker tripped on purpose, two defects found by detonating | 5 artefacts + GIF |

56 ADRs across the four. Every scanner suppression carries a written justification.

## 3. How they interlock

```mermaid
flowchart TB
    subgraph AWS["AWS — AwLZ"]
        ORG["Organization: 2 OUs, 4 accounts<br/>SCPs, org trail, GuardDuty, Config, Security Hub"]
        LAB["awlz-lab<br/>isolated detonation account"]
    end

    subgraph SUPPLY["Supply chain — ProvenancePipeline"]
        CI["GitHub Actions: build → SBOM → grype gate<br/>→ cosign keyless → SLSA attestation"]
        REG[("GHCR + public Rekor")]
    end

    subgraph CLUSTER["Runtime — KateClusters"]
        K8S["kubeadm 1.34 on Debian 13 VM<br/>CIS-hardened, PSA restricted, default-deny netpol"]
        DET["Falco eBPF + audit → Loki → Grafana → alert-sink"]
    end

    subgraph RESP["Response — PontoAntiCrack"]
        PAC["CloudTrail → EventBridge → Lambda<br/>s3-public, iam-key-leak, sg-open"]
    end

    ORG -->|org trail + lab account| PAC
    LAB -.->|Stratus detonation target| PAC
    CI --> REG
    REG -->|Kyverno verifyImages<br/>Enforce + failurePolicy Fail| K8S
    K8S --> DET

    classDef todo stroke-dasharray: 5 5
    class PAC todo
```

Two real dependencies, and both are one-directional:

1. **PontoAntiCrack consumes AwLZ.** The org trail it reads and the lab account it detonates
   in are both AwLZ resources. It cannot be meaningfully built before AwLZ's logging exists —
   and AwLZ's logging exists. The dependency ran in both directions in the end: AwLZ's
   trail carried the events PAC detects, and AwLZ's permissions-boundary Config rule found
   three PAC roles that predate it.
2. **ProvenancePipeline enforces on KateClusters.** The Kyverno policy belongs to
   ProvenancePipeline; the cluster it admits into belongs to KateClusters. That integration
   is complete: one signed image is admitted and three deny paths are recorded.

Nothing else couples. AwLZ and KateClusters were built in parallel on purpose — one waits on
AWS, the other never touches it.

### What the couplings cost — [program threat model](docs/threat-model.md)

Each repository carries its own threat model, and each is internally sound. Modelling the
program **as a whole** produced eight threats that none of the four can see from the inside,
because they live in the space between scopes rather than inside one. Five have no control
yet, which the document says rather than implies. The three worth reading first:

- **Nothing asserts the enforcement policy is still installed.** `verify-provenance` is
  authored in ProvenancePipeline and runs in KateClusters. One repo's CI tests policy *files*;
  the other's tests cluster *manifests*. `kubectl delete clusterpolicy verify-provenance`
  disables admission control **while every gate in the program stays green.** Neither repo is
  wrong; the check belongs to a boundary neither owns.
- **One GitHub account is both infrastructure takeover and a signing capability.** AwLZ trusts
  it to apply Terraform to a live organization; ProvenancePipeline trusts it as the Sigstore
  identity a cluster enforces. Both models are individually correct and neither can see the
  shared root. The gates are also asymmetric: Terraform apply is gated on a protected
  environment, **image signing on a push to `main`** — the weaker gate guards the thing that
  mints artifacts a cluster is configured to trust.
- **Four "out of scope" declarations compose into one unowned asset.** Every repository
  excludes operator endpoint security, correctly. That workstation holds the Identity Center
  session, the GitHub credentials, the kubeconfig, and the SSH key to the cluster host — the
  only asset from which all four layers are reachable, and the only one no model claims.

And one structural finding with no threat ID: **the program has two disjoint evidence
planes.** AwLZ and PontoAntiCrack share the org CloudTrail. KateClusters' Falco and audit
telemetry terminate in a local Loki with no path into it. Both planes work and both have
measured evidence — but no query spans them, so an attacker moving between the AWS
organization and the cluster produces two unrelated halves of a story. The trade is defensible
against a USD 20/month ceiling. Making it silently would not be.

---

## 4. Per project

### AwLZ — AWS Landing Zone

**Live.** Six stacks applied against a real organization: `bootstrap`, `org-root`,
`guardrails`, `logging`, `detection`, `ci-oidc`. Home region `sa-east-1`, `us-east-1` also
permitted because global services report there regardless.

- 2 OUs, 4 member accounts, **root credentials deleted org-wide** via centralized root access
- 4 SCPs attached to both OUs, each **probed from inside a member account** — the only way to
  test an SCP is to be denied by one
- Org trail → Object Lock COMPLIANCE archive in a separate account
- GuardDuty + Security Hub CIS + Config across 5 accounts + Access Analyzer, delegated
- CI: `fmt`, `tflint`, `trivy`, `checkov`, `validate` ×6, plus a real `terraform plan` against
  live AWS via OIDC. `main` requires a PR **and** passing checks
- Permission boundaries + a Config rule for T5, and a break-glass alarm for T8 that reached
  `ALARM` on real recovery-role assumptions rather than a synthetic metric
- A read-only plan role per member account, so all six stacks plan in CI with no
  administrator anywhere
- Gate baseline: checkov 477 passed / 0 failed / 69 skipped

The `awlz-lab` control-group experiment is done and its result is negative, which is the
interesting part: detaching the SCPs from the lab did not move a single one of 35 CIS
controls, because no CIS v3.0.0 control reads an SCP. A benchmark score measures resource
configuration; it cannot measure a preventive guardrail. The behavioural probes — denied,
then allowed, then denied again — are what show the SCPs working.

Cost actuals closed 2026-08-04, and the first steady-state month — September 2026, outside
both service trials — closed at USD 7.31 invoiced. See §7.

### ProvenancePipeline — supply chain

**CI half complete and verified.** Go service (stdlib only, so any CRITICAL finding is real
signal), multi-stage Dockerfile with both bases digest-pinned to distroless `:nonroot`.

Pipeline: test → build/push GHCR → syft SBOM (SPDX + CycloneDX) → **grype gate on CRITICAL,
hard** → cosign sign keyless → attest SBOM → attest SLSA v1 → GitHub provenance → `verify`
job on a clean runner **including a negative control** (verifying an unsigned digest must
fail, or the build fails).

Trust anchor, pinned everywhere and derived from one place in the workflow:

```
identity: https://github.com/PontoPe/ProvenancePipeline/.github/workflows/release.yml@refs/heads/main
issuer:   https://token.actions.githubusercontent.com
```

**Enforcement is live.** Kyverno v1.18.2 installed digest-pinned under the cluster's
default-deny egress, `verify-provenance` in `Enforce` with `failurePolicy: Fail`, deny-path
tests against the real registry, and the demo recorded — 494 KB GIF plus the `.cast` beside
it, with `docs/evidence/admission-enforcement.md` generated by the same script.

The demo runs four cases, and the last two are what make it worth watching:

1. our image by digest, signed by the release workflow → **admitted**
2. an ordinary unsigned public image → denied
3. **an image genuinely Sigstore-signed by Kyverno's own release workflow → denied.** A valid
   signature is not enough; it has to be *our* identity. Most admission demos stop at case 2
   and only prove "has a signature"
4. our image, our signature, referenced by **tag** → denied for a missing digest, which is
   the digest-pinning claim proved rather than asserted

Honest limit stated in the repo: **SLSA Build L2, not L3.** The provenance predicate is
assembled in the same job that builds the image, so anything compromising that job can write
its own provenance. L3 needs `slsa-github-generator` in an isolated context.

**Active T9:** ADR-005's original enforcement assumption was backwards; ADR-009 records that
Kyverno can discover GitHub's provenance bundle on GHCR, not cosign's. That GitHub step is
gated on the repo staying public, so making it private denies every subsequently built image
at admission. E1 can close the coupling with cosign 2.x; leaving the risk stated is allowed.

### KateClusters — hardened cluster + detection

**Built, hardened, exercised.** kubeadm 1.34.10 on Debian 13, Calico 3.32.1, single node in a
VMware VM with three snapshots (`base_installed` → `bench-before` → `hardened`).

- **CIS: PASS 67 → 86, FAIL 12 → 0, WARN 47 → 40.** "100%" means `PASS / (PASS + FAIL)` — 40
  manual-review WARNs remain. Always quote the denominator
- Secrets verified encrypted at rest in etcd; PSA verified rejecting a privileged pod with a
  real 403
- All four attack sims run, with real Falco lines, real audit events, measured time-to-alert
- The alert path terminates in an in-cluster `alert-sink`, so "the alert was delivered" is a
  checkable claim rather than an assumption

Open: the mining-port Falco rule cannot fire when egress is blocked (prevention and detection
are not independent there), Falco not yet fully offline, no low-and-slow authz rule, no
CPU-anomaly signal for T2, kubescape/polaris unverified, no demo GIF.

### PontoAntiCrack — detection and response

**Validated and partially applied, then stopped safely.** Three detections, each a complete
unit: EventBridge pattern, Lambda handler, scoped IAM policy with **explicit denies**,
README, fixtures, tests.

- 171 tests passing. Per detection: the pattern matches, the pattern **rejects the
  plausible-but-benign near-miss**, and the handler acts correctly against `moto`
- Terraform tracks 31 stable resources. The three Lambdas are `Active/Successful` in
  `lab`, `dry_run=true`, with zero EventBridge targets and zero taints. No technique was
  detonated; Stratus v2.34.1 reports all 99 techniques `COLD`
- The regional concurrency quota is 10. The design needs 25 to reserve 5 for each function
  while leaving 10 unreserved. AWS rejects a request for 25 because the self-service
  minimum is 1000, so no request was created and `awlz-lab` was released
- Pipeline order is the security property and lives in exactly one place:
  `plan → exclusion tag → SNAPSHOT → circuit breaker → dry-run gate → apply → audit close →
  alert`. A handler implements `plan()` and `apply()` and nothing else, so it *cannot*
  snapshot late or skip the breaker
- ~USD 2.35/month at rest, 77% of it flat charges

The gap that matters: **all 15 event fixtures are derived from AWS documentation, not from
observed events.** Marked in the fixture, the metadata, the README and the threat model, and
enforced by a test that fails if the markers stop being accurate. The local pattern evaluator
is also a reimplementation — a green test means "the pattern says what I meant", not
"EventBridge agrees".

Three load-bearing assumptions each die to a single `aws events test-event-pattern` call, and
that call is step 3 of the apply order. **A `false` there means the detection is dead
regardless of the 167 tests.**

---

## 5. The discipline that makes it credible

This is the part that generalises, and the part worth protecting when it gets inconvenient.

- **Empty was a valid state.** `PontoAntiCrack/docs/evidence/` stayed empty until something
  had actually been proven there; filling it by hand would have discredited the other three
  repos. It now holds four artefacts, and the two techniques that were never detonated still
  have no numbers claimed for them.
- **Negative tests are mandatory.** A pattern tested only for what it catches matches
  everything, forever, silently. PAC's CI fails a pattern test with no `assert not matches`.
  ProvenancePipeline's `verify` job fails if an *unsigned* digest verifies successfully.
- **Gates are not negotiable.** No `continue-on-error`, no `soft_fail`, no raised threshold.
  A gate switched off to make a run green is worse than no gate, because it also lies.
- **Suppressions carry reasons.** All 69 checkov skips in AwLZ and all 6 in PAC have an inline
  justification; where the finding is real, a threat-model ID and the stack that closes it.
- **Provenance markers on unverified data**, enforced mechanically rather than by memory.
- **Limits are stated in the strong form.** "SLSA L2, not L3." "No multi-tenant isolation is
  claimed." "100% means PASS/(PASS+FAIL)." Overstating is worse than a lower number.
- **Documented failures beat quiet patches.** Where a control was found broken, the writeup
  says it was broken and why, rather than showing the fixed version as if it always worked.

## 6. The five findings worth telling

Interviews are won on these, not on the benchmark score. All five came from running the
thing, and none could have been found by reading documentation.

**1. The dead man's switch was permanently firing, so it could never detect anything.**
Falco emits its heartbeat at `Informational`; falcosidekick's Loki output filtered at
`notice`. No heartbeat ever reached Loki, so the query returned empty whether Falco was alive
or dead, and the alert sat forever in `NoData → Alerting`. *An alert that always fires is
indistinguishable from no alert.* Fixed, then verified by watching it resolve when healthy and
fire again when killed.

**2. The measured detection-off window was 24m36s, not the ~15 min the docs claimed.** The
query window is `[15m]` and the rule is `for: 10m`, so the last heartbeat must age out of the
window before the `for` even begins. That is the real window an attacker has.

**3. A NetworkPolicy made detection un-restartable, and it looked fine for hours.**
`falcoctl-artifact-install` needs outbound 443; the falco-namespace default-deny blocked it.
The initial install ran *before* the policy, so nothing appeared wrong until a node reboot —
after which Falco alone failed to come back while everything else recovered. Order-dependent
success masking a broken steady state.

**4. The guardrails blocked their own deployment, twice.**
`config:PutConfigurationRecorder` both creates a recorder and neuters one, and
`awlz-config-aggregator` matched the protected `awlz-*` prefix. Both SCPs now separate
*destructive* actions — never exempt — from actions deployment also needs.

**5. The GitHub OIDC `sub` is not `repo:owner/name`.** This account issues immutable subject
claims: `repo:PontoPe@96898980/AwLZ@1315312585`, embedding numeric owner and repo IDs so a
rename cannot silently transfer trust. Nothing in the STS error hints at it, and the tempting
fix — `StringLike` — would match a fork's pull request, which is the one path that must never
hold credentials.

Two more with the same shape, cheaper to tell: `aws:PrincipalOrgID` does not exist on a
service principal (Config calls as `config.amazonaws.com`, so the condition could never
match), and AWS's own published CloudTrail bucket policy is wrong for ACL-disabled buckets
because it requires `s3:x-amz-acl`, which `BucketOwnerEnforced` never sends.

## 7. Cost — September 2026, the first steady-state month

One USD 20/month ceiling shared across everything, with alerts at 85% and 100% actual plus
100% forecast. **This section is an actual, not a projection.** Every window below closed
with `Estimated: false`; the working is in [AwLZ/docs/cost.md](../AwLZ/docs/cost.md).

| Source | July gross | August run rate | **September, closed** |
|---|---|---|---|
| AwLZ — 4 CMKs, S3, CloudTrail, Config, GuardDuty, Security Hub | USD 1.47 | USD 4.67 | **USD 5.63** |
| PontoAntiCrack at rest — 1 CMK, 1 secret, 3 idle Lambdas | USD 0.02 | USD 1.40 | **USD 1.40** |
| Tax | — | USD 0.31 | **USD 0.28** |
| KateClusters | USD 0 — local VM | USD 0 | USD 0 |
| ProvenancePipeline | USD 0 — GitHub-hosted | USD 0 | USD 0 |
| **Total** | **USD 1.48** | **USD 6.38** | **USD 7.31** |

September is the first month with neither credits nor service trials: **USD 7.31 invoiced,
37% of the ceiling**, against a 2026-07-30 projection of USD 13.73 gross.

**July's invoice was USD 0.** Credits covered the entire USD 1.48 and stopped at the month
boundary. Both numbers belong in the record: the net is what was paid, the gross is what the
architecture costs, and only one of them is evidence about the design.

Four things the measurement changed:

1. **Credits are not a guardrail, and their expiry is silent.** They covered 100% of July.
   The budget alarms watch spend, so they could not see the cliff — the spend they were set
   against was being hidden by the thing that expired.
2. **Config was over-projected 3×, and the reason generalises.** The estimate extrapolated
   33 configuration items from a *deployment* day across a month. Config bills per recorded
   item and per rule evaluation, and the boundary rules are change-triggered, so a quiet
   month bills almost nothing — September recorded 13 items, USD 0.04. **Config cost tracks what the org does,
   not how long it exists.** Neither USD 3.12 nor USD 0 is a steady state.
3. **The KMS line matched exactly** — USD 4.00 for four keys, the only line the first closed
   window confirmed outright. A fifth key exists org-wide, `alias/pac` in `awlz-lab`, and it
   is PontoAntiCrack's. A consolidated KMS charge of USD 5.00 read against AwLZ's four-key
   table looks like an error and is not.
4. **Secrets Manager was missing from the model entirely** at USD 0.40/month — invisible
   rather than estimated low, which is the worse of the two failures.

The measurement trap, recorded because it produced a wrong answer first: **grouping Cost
Explorer by `SERVICE` without filtering `RECORD_TYPE` nets credits into the same row as
usage.** Every service reads USD 0 under that grouping, and a healthy Config recorder
emitting 325 items is indistinguishable from a broken one.

**The trial cliff landed, and it was small.** GuardDuty and Security Hub left their trials
around 27 August. In September, Security Hub billed 870 compliance checks — USD 0.87 against
2,760 checks and USD 2.76 projected — and GuardDuty USD 0.08 against USD 0.25. Together USD
0.95/month, not the USD 3.01 the model reserved. The projection's 2× re-evaluation margin was
not used in a month with no changes. **USD 7.31 is a quiet-month figure**: Config and Security
Hub are change-driven, and a month with real Terraform activity has not been measured.
`get-cost-forecast` still fails (`InternalFailure` on 2026-10-08); the budget's own forecast
for October is USD 6.34.

The Security Hub reduction is applied: `get-enabled-standards` on the management account
returns `[]`, with CIS v3.0.0 retained in `awlz-security`.

Still true, and still the realistic way to blow the budget: **a forgotten Stratus instance is
~USD 9/month.** Run `stratus status` after every detonation session. Nothing in the four
stacks comes close.

## 8. Environment

Windows 11 workstation, PowerShell 7, Ryzen 9 7900X / 32 GB. The cluster is a Debian 13 VM on
the same box under VMware Workstation Pro, reached over SSH (`ssh kate`).

Traps that have each cost real time:

- **Nothing is on `PATH` in a fresh shell.** `terraform`, `tflint`, `trivy`, `shellcheck` live
  under `%LOCALAPPDATA%\Microsoft\WinGet\Packages\<Vendor>.<Tool>_*\`; `ruff`, `mypy`,
  `pytest`, `checkov` under `%LOCALAPPDATA%\Python\pythoncore-3.14-64\Scripts`. `python -m
  <tool>` always works. `vmrun` is at `C:\Program Files\VMware\VMware Workstation\`.
- **PowerShell `&&` short-circuits.** A chained version check stops at the first failure and
  the rest silently never run — this produced a false "aws CLI is missing".
- `terraform -chdir=$var` does not expand the variable in PowerShell. Use `Set-Location`.
- **In a non-interactive SSH shell `/usr/sbin` is not on `PATH`** — `kubeadm` and `swapon`
  report `command not found` while existing.
- `winget install` takes one package ID per call. `Sigstore.Cosign` installs no shim.
- Makefiles assume POSIX — Git Bash or WSL.
- SSH keys with non-default names are ignored unless declared in `~/.ssh/config`.
- **AWS auth is IAM Identity Center SSO, profile `mgmt`, `sa-east-1`. Twelve-hour sessions.
  There is no static access key anywhere, by design — never introduce one.**

## 9. What is next

One TrustStack overlooker coordinates one persistent owner per repository. Owner prompts
15–18 replace manual phase-by-phase handoffs; prompt 19 hands the whole program to a new
overlooker.

| Priority | Work | Gate | Owner |
|---:|---|---|---|
| ~~1~~ | ~~C6 cost actuals~~ | **Closed 2026-08-04.** July returned `Estimated: false`; §7 is an actual | AwLZ |
| ~~1~~ | ~~September cost actual~~ | **Closed 2026-10-08.** USD 7.31 invoiced, first steady-state month | AwLZ |
| 2 | *Optional.* Detonate `s3-public` and `iam-key-leak` | none; the lab is free | PontoAntiCrack |
| 3 | *Optional.* Close E1 by pinning cosign 2.x | none | ProvenancePipeline |

**"Do not enter live PAC remediation before the fixtures are real" was the right rule.**
Capturing real events and then detonating found two defects that every green gate had
missed: a loop guard that trusted the caller-chosen session name, and a pattern that knew
only one of the two CloudTrail encodings of `AuthorizeSecurityGroupIngress`. Live
remediation before that would have run on a pattern that did not match the attack.

## 10. Cross-cutting pass

Closed 2026-07-30: all sibling trees clean and pushed; AwLZ handbook rename finished; empty
stack scaffolds removed; its handoff is in-repo; KateClusters' namespace-scoped default-deny
and `AlwaysPullImages` posture are explicit; stale state/path/ADR references corrected;
`AGENTS.md` is canonical in all four repos; recording gates were added and deliberately
tested in AwLZ, KateClusters and PontoAntiCrack.

All of that evidence work is now done: demos and public releases in all four repos, AwLZ's
GuardDuty, CIS control experiment, T5/T8 controls and least-privilege CI, and PAC's
deployment, detonation and measured remediation. AwLZ's cost actuals closed on 2026-08-04
against the first closed billing window, and the delta against the superseded projection is
kept in `AwLZ/docs/cost.md` rather than overwritten. The September actual — the first
month outside two service trials — closed on 2026-10-08 at USD 7.31. ProvenancePipeline's T9 visibility coupling
remains an explicit, optional risk.

---

## 11. The demo standard

`ProvenancePipeline/docs/demo-recording.md` is the house recipe, written from actually
recording one, with the mistakes in it. `ProvenancePipeline/scripts/demo-record.sh` is the
same thing runnable. The other three repos follow it rather than rediscovering it.

What every recording inherits:

- **`asciinema rec --command <script>`, never a live shell.** No shell means no `PS1`, which
  is what normally leaks `user@hostname`, the working directory, and the kube-context.
- **Record raw; pace at render time.** `--idle-time-limit` on `rec` destroys real pause
  durations permanently. Cap idle in `agg` instead, where it stays reversible.
- **Real latency is the asset.** The 1–3 s a webhook spends fetching a bundle and checking a
  transparency log *is* the demo. Padding it or compressing it both lie about the work.
- **Commit the `.cast` next to the `.gif`.** ~6 KB of JSON: greppable, re-renderable, and the
  only form of a recording a reviewer can audit. A GIF cannot be searched.
- **`--speed 0.6`, `--last-frame-duration 6`.** Frames that must be *read* need ~1 s per two
  lines; frames that just scroll can be 100 ms.
- **Same geometry, theme and font across all four**, so they read as one system.
- **20–40 s, under ~1 MB.** The reference GIF is 494 KB over 31 s.
- **Watch it before committing.** `repo_invariants.sh` greps text; it cannot see inside a GIF.
  A LAN address or account ID rendered as pixels passes every check.

Corrections already learned, to apply from the first take rather than rediscover: `clear`
between sections so each frame is self-contained, `kubectl wait` rather than `sleep`, one
warm-up run so the first case is not cold-start slow, decide the terminal width against your
longest line *before* recording, and colour only the first line of a multi-line error rather
than the whole block.

## Reading order for someone new

1. This file.
2. [`docs/threat-model.md`](docs/threat-model.md) — the **program-level** model: STRIDE over
   the seams between the four repositories, the twelve risks accepted across all of them, and
   eight cross-boundary threats that no component model can see from the inside. Five of the
   eight have no control yet, and say so.
3. The per-repo handoff: `AwLZ/docs/AwLZ-handbook.md`; others —
   `docs/{PROVE,KATE,PAC}handoff.md`.
4. `docs/architecture.md` in the repo you care about — read it before disagreeing with a
   design choice; the reasoning is probably already there.
5. The repo's own `docs/threat-model.md` — threats with likelihood, impact, and **residual
   risk**. Authoritative inside its scope; the program model is authoritative between them.
5. `docs/evidence/` — what was actually proven.
6. `AGENTS.md` — conventions, environment traps, and the decisions not to relitigate.
