# TrustStack — the program handbook

The complete account of the portfolio: what each of the four repositories is,
how each one works internally, what was proved and by what method, what proving
them actually found, and what is deliberately still open.

**This document is self-contained.** It assumes you know what a cloud account
and a container are, and nothing else about this project. Every term specific to
the domain is defined in §2 before it is used. If you read it end to end you
will understand the program and all four subsystems without opening anything
else; the per-repository handbooks add build-order detail and session history,
not new concepts.

Written **2026-07-30**, the day the last layer closed; cost re-measured
2026-08-04 against the first billable window, and counts re-derived 2026-08-15.
Every number was read out of a repository or a command rather than carried over
from an earlier document.

**Numbers in §3 drift with every commit.** What goes stale, where, and what
refreshes it is
[ROADMAP.md § Maintenance](ROADMAP.md#maintenance--what-goes-stale-where-and-what-refreshes-it).

| Where to go next | For |
|---|---|
| [README.md](../README.md) | The one-page portfolio summary |
| [ROADMAP.md](ROADMAP.md) | Item-by-item state, sections A–E |
| [PROGRESS.md](PROGRESS.md) | Where the last working session stopped |
| [AGENTS.md](../AGENTS.md) | Operating manual for whoever works on it next |

---

## Table of contents

1. [The thesis, and the rule that follows from it](#1-the-thesis-and-the-rule-that-follows-from-it)
2. [Vocabulary](#2-vocabulary)
3. [Final state](#3-final-state)
4. [AwLZ — the cloud governance layer](#4-awlz--the-cloud-governance-layer)
5. [PontoAntiCrack — the response layer](#5-pontoanticrack--the-response-layer)
6. [KateClusters — the runtime layer](#6-kateclusters--the-runtime-layer)
7. [ProvenancePipeline — the supply-chain layer](#7-provenancepipeline--the-supply-chain-layer)
8. [How the layers couple](#8-how-the-layers-couple)
9. [What proving each layer actually found](#9-what-proving-each-layer-actually-found)
10. [The method, and where it runs out](#10-the-method-and-where-it-runs-out)
11. [The honesty discipline, mechanised](#11-the-honesty-discipline-mechanised)
12. [Cost, and the decision it forced](#12-cost-and-the-decision-it-forced)
13. [Operating and verifying it from cold](#13-operating-and-verifying-it-from-cold)
14. [What is open, deliberately](#14-what-is-open-deliberately)
15. [If you only read four files](#15-if-you-only-read-four-files)

---

## 1. The thesis, and the rule that follows from it

Four repositories, one claim per layer of a system's trust:

| Layer | Question it answers | Repository |
|---|---|---|
| Cloud governance | Can an account do something nobody watches? | **AwLZ** |
| Artifact provenance | Do I know where this container came from? | **ProvenancePipeline** |
| Runtime | If something breaks in, does anyone find out? | **KateClusters** |
| Response | When something is found, what happens automatically? | **PontoAntiCrack** |

> **The deliverable is not working infrastructure. It is reproducible
> infrastructure plus evidence that the controls do what the documentation
> claims — including where they don't.**

Anyone can apply a Terraform module or install a Helm chart. The part worth
showing is each repository's `docs/evidence/` directory, and the part worth
showing *there* is the entries recording a control failing, a claim being wrong,
or a number coming back worse than promised.

That rule has a cost, and the cost is the point. Three of the four layers had to
publish a result less flattering than the one originally advertised.

## 2. Vocabulary

Everything below is used later in this document. Skip what you know.

### Cloud and AWS

| Term | What it means here |
|---|---|
| **Account** | An AWS billing and isolation boundary. Everything lives inside one. |
| **Organization / OU** | A tree of accounts under one management account. An *organizational unit* is a folder in that tree. |
| **SCP** — service control policy | A rule attached to an OU or account that caps what *anyone* inside it may do, including its administrators. It removes permissions; it never grants them. The only thing that can deny an account admin. |
| **CloudTrail** | The audit log of every API call in an account. An *organization trail* collects all accounts into one place. |
| **GuardDuty** | AWS's managed threat detection: it watches logs and network data and emits *findings*. |
| **Security Hub** | Aggregates findings and scores an account against a benchmark such as CIS. |
| **AWS Config** | Records the configuration of every resource over time and evaluates *rules* against it. |
| **EventBridge** | An event bus. A *rule* holds a pattern; matching events are delivered to a target such as a Lambda function. |
| **Lambda** | Run a function without a server. *Reserved concurrency* caps how many copies may run at once. |
| **KMS / CMK** | Key management. A *customer-managed key* is one you own, with a policy saying who may use it — unlike an AWS-managed key, which has none you can write. |
| **Object Lock (COMPLIANCE)** | S3 storage mode where an object cannot be deleted or overwritten until its retention expires — not even by the account root. |
| **OIDC federation** | A way for GitHub Actions to obtain short-lived AWS credentials by proving *which repository and which workflow* is running, instead of holding a stored access key. |
| **Terraform** | Infrastructure as code. `plan` shows what would change; `apply` performs it; *state* is the file recording what it believes exists. |
| **Stratus Red Team** | An open-source tool that executes real attack techniques against a cloud account so detections can be tested. |

### Kubernetes and supply chain

| Term | What it means here |
|---|---|
| **kubeadm** | The upstream tool that builds a real Kubernetes cluster, as opposed to a toy local one. |
| **PSA** — Pod Security Admission | Built-in policy levels per namespace. `restricted` forbids privileged containers, host mounts and similar. |
| **NetworkPolicy** | Firewall rules for pods. **Namespaced**: it protects only the namespace it is created in. |
| **RBAC** | Who may call which Kubernetes API verb on which resource. |
| **Falco** | Runtime security monitoring. Watches system calls through **eBPF** — an in-kernel mechanism for safe instrumentation — and alerts on suspicious behaviour. |
| **Loki / promtail / Grafana** | Log store, log shipper, and dashboard/alerting front end. |
| **kube-bench** | Runs the CIS Kubernetes Benchmark against a cluster and reports PASS / FAIL / WARN. |
| **Admission control** | The API server asks an external policy engine whether to accept a resource. **Kyverno** is that engine here. `Enforce` means "reject", and `failurePolicy: Fail` means "if the engine is unreachable, reject rather than admit". |
| **SBOM** | Software bill of materials — the inventory of everything inside an image. **syft** produces one; **grype** and **trivy** scan for known vulnerabilities. |
| **cosign / Fulcio / Rekor** | Sigstore. `cosign` signs artifacts; *keyless* signing gets a short-lived certificate from **Fulcio** bound to a CI identity, and the record goes into **Rekor**, a public append-only transparency log. No long-lived private key exists to steal. |
| **Attestation** | A signed statement *about* an artifact — for example its SBOM, or its **SLSA provenance**: who built it, from which source commit, with which inputs. |
| **SLSA levels** | A supply-chain maturity scale. L2 requires a hosted builder and signed provenance; L3 additionally requires provenance generated in a context the build job cannot tamper with. |

## 3. Final state

| Repository | Commits | Public | Applied to | Evidence artefacts | Demo |
|---|---:|---|---|---:|---|
| **AwLZ** | 73 | ✅ | a live 5-account AWS organization | 5 | ✅ |
| **PontoAntiCrack** | 41 | ✅ | the isolated `awlz-lab` account | 5 | ✅ |
| **KateClusters** | 44 | ✅ | a live single-node cluster on a VM | 2 + 4 writeups | ✅ |
| **ProvenancePipeline** | 25 | ✅ | GHCR and the KateClusters cluster | 2 | ✅ |

56 architecture decision records across the four.

The definition of finished, agreed before the work started: code applied to real
infrastructure, real artefacts in `docs/evidence/`, a demo GIF with its cast, a
threat model whose residual risks are stated rather than implied, and a public
repository. **All four layers meet it.**

The last open item, AwLZ **C6**, closed on 2026-08-04 when the July window
became billable. Cost is a measured actual now: gross usage USD 1.4830, fully
covered by credits, and an August run rate of USD 6.38/month against a USD 20
ceiling. September 2026, the first month with neither credits nor service trials,
closed at USD 7.31 invoiced (USD 7.03 gross usage). It is reported gross, because the zero invoice would understate the
model by everything it was meant to measure. See §12.

**Nothing in the program is open on a deadline.** What remains is optional work
and ordinary maintenance — what goes stale, where, and what refreshes it is
[ROADMAP.md § Maintenance](ROADMAP.md#maintenance--what-goes-stale-where-and-what-refreshes-it).

---

## 4. AwLZ — the cloud governance layer

**Repository:** `github.com/PontoPe/AwLZ` · **Language:** Terraform ·
**Region:** `sa-east-1`, with `us-east-1` also permitted because several AWS
services report globally there.

### What it is

A multi-account AWS landing zone: the governance floor an organization stands
on, rather than an application. Most "AWS security" portfolios harden a single
account. Real organizations fail at the boundary — an account nobody governs, a
region nobody watches, an access key in a CI runner. This builds the boundary
itself as reproducible code.

### The organization it manages

```
Management account            Organizations, SCPs, Identity Center, Terraform state, org trail
├── OU: Security
│   ├── awlz-log-archive      destination for the organization CloudTrail, holds the archive key
│   └── awlz-security         delegated administrator for GuardDuty, Security Hub, Config, Access Analyzer
└── OU: Workloads
    ├── awlz-dev
    └── awlz-lab              the throwaway account: detonations and experiments happen only here
```

Root credentials are **deleted** from all four member accounts through
centralized root access, so the only interactive way in is IAM Identity Center.

### The six stacks

Each is an independent Terraform root; they are applied in this order because
each depends on the one before.

| Stack | What it creates |
|---|---|
| `live/bootstrap` | The S3 bucket holding Terraform state, its customer-managed key, versioning, a TLS-only policy and native S3 locking |
| `live/org-root` | The two OUs, the four member accounts, centralized root access, trusted service principals |
| `live/guardrails` | The four service control policies and their attachments |
| `live/logging` | The organization CloudTrail, its Object Lock archive in the log-archive account, a 14-day CloudWatch tail, and the break-glass alarm |
| `live/detection` | GuardDuty, AWS Config with its recorder in every account, Security Hub with the CIS benchmark, Access Analyzer, permission boundaries and their Config rule — all delegated to `awlz-security` |
| `live/ci-oidc` | The GitHub OIDC provider, a read-only plan role, an apply role gated behind a protected environment, and one read-only role per member account |

Ten reusable modules sit underneath (`organizations`, `scp`, `logging`,
`detection`, `config-recorder`, `config-rules`, `iam-oidc`,
`permission-boundary`, `boundary-config-rule`, `member-plan-role`).

### The four guardrails

An SCP is the only mechanism that can deny an account administrator, which is
why every one of these is probed *from inside a member account while holding
administrator there*. A test as anything less privileged would prove nothing.

| Policy | What it denies |
|---|---|
| `deny-unapproved-regions` | Any API call outside the allowed regions |
| `protect-security-services` | Destroying or weakening CloudTrail, Config, GuardDuty and Security Hub. Split into two statements: *destructive* actions have no exemption at all, while actions deployment also needs exempt the deployment principals |
| `protect-guardrail-roles` | IAM writes against `awlz-*` roles and the recovery role |
| `require-permissions-boundary` | Creating a role, or changing a boundary, without the exact account boundary ARN. The recovery role is the sole exception |

### Threat model

| # | Threat | Control | State |
|---|---|---|---|
| T1 | CI credential theft → account takeover | GitHub OIDC, no static keys anywhere, role trust pinned to exact `sub` claims | applied |
| T2 | Attacker disables logging to hide activity | `protect-security-services` | applied |
| T3 | Resource sprawl in unwatched regions | region allow-list | applied and probed |
| T4 | Log tampering or deletion | separate log-archive account, key held there, Object Lock COMPLIANCE | applied and verified |
| T5 | Privilege escalation via IAM in a member account | permission boundary per account, an SCP requiring it on new roles, and a Config rule that reports any customer role without it | applied 2026-07-30 |
| T6 / T6b | Terraform state exfiltration, or read untraced | dedicated key, TLS-only policy, CloudTrail data events scoped to the state bucket | applied |
| T7 | Malicious or mistaken Terraform merged | `tflint`, `trivy config`, `checkov`, a real plan on every pull request, gated apply, protected `main` | applied |
| T8 | Guardrails lock out emergency access | documented break-glass role, plus a CloudWatch alarm on assumption of the four exact recovery-role ARNs | applied and observed firing |
| T9 | Member account root used outside Identity Center | root credentials deleted org-wide | eliminated |

### Decisions worth knowing

Nineteen ADRs; the ones that shape everything else:

- **No static AWS access keys, anywhere** (ADR-003). Every path in is federated.
- **SCPs attach to OUs, never the organization root** (ADR-008), so a bad policy
  cannot lock out the management account.
- **Centralized root access, and no blanket root-deny SCP** (ADR-007) — the
  member accounts have no root credentials to deny.
- **Detection is delegated to the security account** (ADR-013): the management
  account is not the place to run the tools that watch the management account.
- **Guardrails exempt their own deployment principals** (ADR-014), after the
  guardrails blocked their own deployment twice.
- **Permission boundaries are preventive and independently detected** (ADR-017).
  The SCP stops new unbounded roles; the Config rule reports the ones already
  there. Neither substitutes for the other.
- **Cross-account CI plans use dedicated read-only roles** (ADR-019). Before
  that, planning the logging and detection stacks from CI would have required a
  role that could assume administrator everywhere — on unreviewed pull requests.

### What is proved, and how

`docs/evidence/` holds four write-ups and one generated score export:

- **`scp-verification.md`** — every policy probed from inside a member account,
  including a negative control proving the role protection is scoped rather than
  a blanket deny, and an incident where a guardrail correctly blocked the
  cleanup of a mistake. Also the lab control experiment; see §9.
- **`logging-verification.md`** — a real object delivered under the organization
  prefix, and CloudWatch streams from more than one account.
- **`detection-verification.md`** — five Config recorders reporting `SUCCESS`,
  which is what proves the whole cross-account, key-encrypted delivery path
  works; the GuardDuty enrollment closure; and the T5/T8/C5 verification.
- **`cis-score.txt`** — CIS v3.0.0 per account, regenerated by `make evidence`.

Gate baseline: checkov 477 passed, 0 failed, 69 justified skips; `tflint` and
`trivy` clean. CI plans all six stacks against real AWS through OIDC and holds
administrator in no account.

### Limits

The CIS benchmark measures resource configuration and cannot measure a
preventive guardrail — proved, not assumed (§9). Cost actuals are pending a
closed billing window. The permissions-boundary Config rule reports roles it
cannot fix, by design.

---

## 5. PontoAntiCrack — the response layer

**Repository:** `github.com/PontoPe/PontoAntiCrack` · **Language:** Python +
Terraform · **Runs in:** the `awlz-lab` account.

### What it is

Detection-as-code with automated remediation. Named after VAC, the anti-cheat
system: the game keeps running, the cheater gets caught and kicked
automatically. Anyone can enable GuardDuty; the difference between a sysadmin
who knows security and a security engineer is that the detection **is code, has
tests, and was proven by attacking the account**.

### The pipeline

```
API activity ──► CloudTrail (organization trail, from AwLZ) ──┐
                                                              ├─► EventBridge rules ──► Lambda per detection
GuardDuty findings ───────────────────────────────────────────┘                              │
                                                                                              ├─► DynamoDB audit table
                                                                                              └─► Slack notifier
```

Every detection runs through one runtime, and **the order is the security
property**:

```
plan (read-only) → exclusion tag → SNAPSHOT TO AUDIT TABLE →
circuit breaker → dry-run gate → apply → audit close → alert
```

Handlers implement `plan()` and `apply()` and nothing else. They never touch the
audit log, the breaker or the notifier, so they cannot get the order wrong.

### The three detections

| ID | Trigger | Remediation | Detonated |
|---|---|---|---|
| `s3-public` | An ACL, policy or public-access-block change that could expose a bucket | Enable all four Block Public Access settings and reset a public ACL. **The policy is retained as evidence, not deleted** | not yet |
| `iam-key-leak` | A GuardDuty finding of MEDIUM or higher against an access key | Capture the key's last-used record, then set it **Inactive — never deleted**. Root and temporary credentials escalate to a human instead | not yet |
| `sg-open` | Ingress authorised from `0.0.0.0/0` or `::/0`, in **either** CloudTrail encoding | Revoke only the world-open ranges on entries covering a sensitive port | ✅ 5.97 s |

Each detection is a *unit*: an EventBridge pattern, a Lambda handler, a scoped
IAM role, a README, fixtures, and tests for both what it catches and what it must
not. A CI gate fails a partial one, and fails any pattern test with no negative
assertion — a pattern tested only for what it catches matches everything,
forever, silently.

### Decisions worth knowing

Fifteen ADRs; the load-bearing ones:

- **Coarse pattern, precise handler** (ADR-002). A pattern cannot evaluate a port
  range or parse a policy document. The handler reads the resource back and
  decides. This is why a missed event encoding was a missed detection rather
  than a wrong remediation.
- **Snapshot before change, in two writes** (ADR-003). The prior state reaches
  the audit table before anything mutates, so a failed remediation still leaves
  a complete record.
- **One execution role per detection, with explicit denies** (ADR-004) on the
  escalation primitives.
- **Dry run is the default and opting out is explicit** (ADR-007).
- **Circuit breaker in DynamoDB, concurrency cap in Lambda** (ADR-008). Five
  actions per five-minute window, counting dry runs.
- **Deactivate credentials, never delete; escalate root** (ADR-009). Deleting a
  key destroys the last-used record, which is often the only evidence of what
  the attacker reached.
- **The pattern evaluator in the tests is a reimplementation** (ADR-010) of the
  EventBridge pattern language, so tests need no AWS account — and it is
  therefore checked against the real service by a separate gate.
- **Fixture provenance is machine-checked** (ADR-013). See §11.

### What is proved, and how

185 tests, and four evidence artefacts:

- **`pattern-gate.md`** — all seventeen fixtures replayed through
  `aws events test-event-pattern`: seventeen agreements, zero disagreements.
- **`fixture-capture.md`** — fifteen of seventeen fixtures are real captured
  events, plus the five places real events disagreed with hand-written ones.
- **`detonation-sg-open.md`** — the technique executed with Stratus Red Team,
  and the two defects it exposed (§9).
- **`time-to-remediate.md`** — **5.97 seconds** from the attacker's API call to
  the rule being revoked, with the group's unrelated port 443 rule left
  untouched; the dry run that changed nothing; and the circuit breaker tripped
  on purpose, holding after five actions with four `BLOCKED` records and four
  ports deliberately left open.

### Limits

Two of three techniques were never detonated, so no latency is claimed for them.
The captured GuardDuty fixtures are service-generated samples: real type,
severity and shape, but no actual compromise produced them. One fixture — the
root-credential case — stays documentation-derived, because no sample can be
issued against the account root and manufacturing a root compromise is not a
reasonable trade. The Slack delivery path is unproven because no webhook exists;
the audit table, not the chat message, is the system of record. The lab is left
running with live remediation enabled, which is the state the measurement was
taken in; any other account starts in dry run and stays there until a week of
real traffic has been reviewed.

---

## 6. KateClusters — the runtime layer

**Repository:** `github.com/PontoPe/KateClusters` · **Runs on:** a dedicated
Debian 13 VMware virtual machine, 4 vCPU / 8 GB / 60 GB, kernel 6.12.96 with
BTF. No paid cloud.

### What it is

A `kubeadm` Kubernetes cluster hardened to the CIS benchmark, with runtime
detection wired to a real alerting path, plus attack simulations that prove the
detections fire. A hardened cluster with no detection is a claim; a cluster with
detection and no attack simulation is an unverified claim.

**Why a virtual machine:** the box the project originally implied would host it
runs real users, and `kubeadm init` disables swap, rewrites the host firewall
and takes over routing. A VM also adds snapshots, which turn the irreversible —
an unrecoverable baseline, a successful escape simulation — into the repeatable,
and bound escape blast radius to the hypervisor. The honest cost: the
workstation must be up for the cluster to be up, so the dead-man's-switch alert
fires on every shutdown. That is correct behaviour and is not tuned away.

### The layers

```
cluster/kubeadm/        cluster config, kubelet and apiserver flags, audit policy enabled
cluster/networkpolicy/  default-deny plus explicit allows, per namespace
cluster/psa/            Pod Security Admission labels per namespace
cluster/rbac/           roles, bindings, service accounts — no cluster-admin service accounts
cluster/secrets/        SOPS + age; no plaintext secret ever in git
detection/falco/        Falco values and custom rules, modern eBPF driver
observability/          apiserver audit policy, Loki, promtail, Grafana dashboards and alerts
attacks/                the four attack simulations
```

The detection path: Falco watches syscalls and the API server writes an audit
log; promtail ships both into Loki; Grafana dashboards and alert rules sit on
top, including a dead-man's-switch that fires if Falco stops reporting.

### Threat model

| # | Threat | Control | Detection |
|---|---|---|---|
| T1 | Container escape to the node | PSA `restricted`, no privileged pods, no host mounts, seccomp | Falco: unexpected `setns`, writes below `/host`, shell in container |
| T2 | Cryptominer in a compromised workload | egress default-deny in repo-owned namespaces | Falco process-name rule — the mining-port rule **cannot** fire while egress is blocked |
| T3 | Lateral movement pod to pod | per-namespace default-deny ingress, explicit allow per service | the simulation proves blocking |
| T4 | Service-account token abuse | least-privilege RBAC, no wildcard verbs, short-TTL projected tokens | audit log: `403` bursts, unusual verb or resource per account |
| T5 | Secrets exfiltration from git | SOPS + age, repo invariants, gitleaks | — |
| T7 | Attacker disables detection | Falco as a DaemonSet with restricted RBAC | Grafana dead-man's-switch |
| T9 | Malicious image | `AlwaysPullImages` plus signature enforcement from ProvenancePipeline | admission deny event |

### Decisions worth knowing

Twelve ADRs, including: `kubeadm` rather than a toy distribution (ADR-001), so
the CIS benchmark is meaningful; Calico as the network plugin (ADR-003); Falco's
modern eBPF driver rather than a kernel module (ADR-006); Loki and Grafana
rather than ELK (ADR-007) on a memory budget; anonymous authentication scoped to
health endpoints rather than disabled outright (ADR-010), because disabling it
breaks the kubelet's own probes; and an in-cluster alert sink (ADR-011) rather
than an unterminated webhook, so delivery is *observable* rather than assumed.

### What is proved, and how

- **`docs/cis-results.md`**, generated from two committed `kube-bench` runs:
  **PASS 67 → 86, FAIL 12 → 0, WARN 47 → 40**, each remediation linked to the
  manifest that fixed it.
- **`docs/attack-detection/`** — four write-ups, one per simulation
  (`escape-attempt`, `cryptominer`, `sa-token-abuse`, `falco-kill`): what was
  run, what the control did, what fired, what the alert looked like, and the gap
  that remained. Raw captured output is committed alongside each.
- A deterministic demo with its cast, and a full CI run — five of five jobs
  green on `main`, so Kubescape and Polaris are verified rather than assumed.

### Limits

One node: hardening and detection, not high availability or multi-tenant
isolation. The CIS figure means `PASS / (PASS + FAIL)`, with 40 manual-review
WARNs still present. Default-deny covers the five namespaces this repository
owns; a newly created namespace is open until it receives policy, because there
is no cluster-wide `GlobalNetworkPolicy`. Falco still needs a narrow outbound
443 rule to fetch its ruleset after a restart. The dead-man's switch was
measured at 24m36s, not the 15 minutes originally estimated.

---

## 7. ProvenancePipeline — the supply-chain layer

**Repository:** `github.com/PontoPe/ProvenancePipeline` · **Language:** Go
(standard library only) · **Registry:** GHCR · **Enforces on:** the
KateClusters cluster.

### What it is

Build → SBOM → vulnerability scan → keyless signature → SLSA provenance
attestation → admission control that refuses anything unsigned.

**The deliverable is the rejection, not the pipeline.** Anyone can show a green
CI run. The recorded demo where a cluster refuses an unsigned image is the
artifact.

### The four-case demo

One Kyverno policy in `Enforce` with `failurePolicy: Fail`:

| Image | Outcome |
|---|---|
| ours, by digest, signed by the release workflow | **admitted** |
| `busybox`, by digest — an ordinary unsigned image | **denied** |
| `kyverno`, by digest — genuinely Sigstore-signed, genuinely in Rekor, **wrong identity** | **denied** |
| ours, by **tag** instead of digest | **denied** |

The third row is the one worth pausing on: that image really is signed and its
entry really is in the public transparency log. It is refused because the
signature is not *ours*. A policy that only asked "is this signed" would have
admitted it.

### The pipeline

`git push` → build → **syft** SBOM in SPDX and CycloneDX → **grype** and
**trivy** scan, failing at CRITICAL with no soft-fail → push to GHCR →
**cosign** keyless signature via Fulcio, recorded in Rekor → **cosign attest**
for SLSA provenance and the SBOM → Kyverno `verifyImages` at admission, matching
identity *and* issuer.

### Decisions worth knowing

Ten ADRs. A stdlib-only Go service (ADR-001) so any CRITICAL finding is real
signal rather than dependency noise; base images pinned by digest, multi-stage,
distroless nonroot (ADR-002); the vulnerability gate never soft-fails (ADR-003);
buildx's own attestations disabled (ADR-004) because they collide with the ones
the policy actually reads; a negative control inside the verify job (ADR-006) so
a verification that cannot fail is never mistaken for one that passes; the
evidence file generated by CI rather than written by hand (ADR-007); and the
enforcement plane installed the way this repo demands of everything else
(ADR-010).

**ADR-009 is the interesting one.** ADR-005 originally said the cosign
attestation is the copy the cluster enforces and GitHub's is the one it cannot
see. On GHCR it is exactly the reverse. Building the cluster half proved it
backwards; the correction is recorded in place, with the original left visible
and a warning at the top of the handoff naming the paragraph to distrust in any
stale copy.

### Threat model

T1 registry compromise, T2 vulnerable dependency, T3 build tampering, T4 signing
key theft (eliminated by keyless signing — there is no long-lived key), T5
signature replay, T6 admission bypass, T7 silent signing, T8 webhook
unavailability (`failurePolicy: Fail`).

**T9 has no control and says so.** Of the four Sigstore bundles per image,
Kyverno can discover only GitHub's, and that publishing step is gated on the
repository being public. Making it private again would deny every new image at
admission. The documented fix — pin cosign 2.x so the legacy layout is published
too — is optional and not urgent, and is tracked as B5.

### Limits

**SLSA Build L2, not L3.** L2 is met: a hosted builder, provenance signed with
the workflow's own OIDC identity through Fulcio, entries in public Rekor, and a
consumer-side check that pins identity and issuer and fails closed. L3 is not,
and the gap is real: the provenance predicate is assembled by a step in the same
job that builds the image, so anything compromising that job could write its own
provenance and have it signed. There is also no automated Rekor monitoring.

---

## 8. How the layers couple

Two real dependencies, both one-directional, and both exercised rather than
diagrammed.

**PontoAntiCrack consumes AwLZ.** The organization CloudTrail it reads and the
lab account it detonates in are AwLZ resources; it could not be meaningfully
built before AwLZ's logging existed. In the end the coupling ran both ways in
practice: AwLZ's permissions-boundary Config rule, applied hours earlier,
immediately reported three PontoAntiCrack roles that predate it — a real finding
handed to the sibling owner rather than silently fixed across a repository
boundary.

**ProvenancePipeline enforces on KateClusters.** The Kyverno policy belongs to
ProvenancePipeline; the cluster it admits into belongs to KateClusters.

Nothing else couples, on purpose. A portfolio where every piece needs every
other piece cannot be reviewed one repository at a time.

## 9. What proving each layer actually found

Every one of these was invisible to a green test suite. This is the section that
justifies the method.

### AwLZ — the headline evidence came back negative

The README promised a CIS score "before versus after" the guardrails. It was not
obtainable: the guardrails went in before Security Hub did, so no un-hardened
"before" existed organization-wide. The honest replacement was a control
experiment on the throwaway account — measure `awlz-lab` with its SCPs, remove
them from that account only, measure again, put them back.

The result: **all 35 controls identical in both states.** No CIS v3.0.0 control
reads a service control policy. A benchmark score describes resource
configuration; it cannot describe a preventive guardrail. Reporting the score as
evidence that the SCPs work — which the original README implied — was measuring
the wrong thing.

What does show them working is behavioural: `ec2:DescribeVpcs` in a denied
region and `cloudtrail:StopLogging` against a trail that does not exist, both
explicitly denied, then allowed during the window, then denied again. Both
probes name resources that do not exist, so nothing was created or destroyed to
produce the evidence.

The experiment also had to be designed so only the lab lost protection. The SCPs
sit on an OU that also holds `awlz-dev`, so they were attached directly to
`awlz-dev` before leaving the OU and removed only after returning — its
effective policy never changed — and reattachment ran from a shell trap so it
would have happened even if the measurement had crashed. Restoration was
verified by an independent read and by a Terraform plan showing zero changes.

### PontoAntiCrack — the detection was fully tested and completely blind

Before the first detonation the suite was green and stayed green: 174 tests at
that point, a coverage gate rejecting any pattern without a negative assertion,
a gate replaying every fixture through EventBridge itself with fifteen
agreements, and fourteen of the fifteen fixtures captured from real CloudTrail
rather than written from documentation. Detonating found two defects anyway —
the second of them with 176 tests passing, after the first had been fixed.

**A loop guard the attacker chooses.** The runtime dropped events whose
principal ARN contained `pac-`, to stop a remediation re-triggering its own
detection. An assumed-role ARN is
`arn:aws:sts::<account>:assumed-role/<role>/<session>`, and the session name is
set freely by the caller on every `AssumeRole`. Stratus happened to run under a
session called `pac-terraform`, so the detection classified the attack as its own
automation and wrote a confident `SKIPPED`. Anyone passing
`--role-session-name pac-anything` was invisible.

**A pattern that knew one of two encodings.** `AuthorizeSecurityGroupIngress` is
recorded two ways. The AWS CLI sends `IpPermissions` and the record nests
`ipPermissions.items[].ipRanges.items[].cidrIp`. A caller using the legacy
top-level parameters produces an empty `ipPermissions` with `ipProtocol`,
`fromPort`, `toPort` and `cidrIp` directly on `requestParameters`. Every fixture
had been produced by the CLI, so the pattern had only ever seen one shape. Port
22 was opened to the internet and the rule did not match — the only thing that
matched was the technique's own Terraform warm-up creating a 443 rule.

Both generalise past this project:

- A security decision made from a field the adversary sets is not a control.
  Ask of any predicate: *who writes this string?*
- Fixtures inherit the bias of whatever produced them. Two tools calling the
  same API are two sources of truth, and a corpus built from one has a blind
  spot invisible from inside it.

What kept both from being worse: the handler reads the resource back instead of
trusting the event, so a missed encoding was a missed detection rather than a
wrong remediation — and dry run was the default throughout, so the first live
remediation happened only after the pattern was fixed.

### KateClusters — the posture claim was broader than the mechanism

The repository described default-deny networking. Kubernetes NetworkPolicy is
namespaced, so the five repo-owned namespaces were covered and a newly created
namespace was fully open. The documents now say exactly that, and record
cluster-wide default-deny as the closing condition. Separately: one Falco rule
cannot fire when egress is already blocked, because it needs an established
socket. Prevention and detection are not independent there, and pretending
otherwise would have double-counted a control.

### ProvenancePipeline — the assumption was exactly backwards

Which of the two attestations the cluster can actually enforce turned out to be
the opposite of what the design assumed. Only building the cluster half revealed
it. See ADR-009.

## 10. The method, and where it runs out

Each repository runs its own gate stack. The pattern that emerged across all
four is a ladder, and every rung catches a class the one below it cannot:

| Rung | Examples | Catches | Cannot catch |
|---|---|---|---|
| Static | `ruff`, `mypy`, `tflint`, `checkov`, `trivy`, `kubeconform`, `shellcheck` | Malformed, unsafe, drifted | Anything about behaviour |
| Unit | `pytest` with fixtures, `cfn-guard` cases, Kyverno policy tests | Wrong logic against a document you wrote | A document that does not match reality |
| Service | `terraform plan`, `aws events test-event-pattern` | Disagreement between your model and the provider | A shape you never handed it |
| Live | apply, detonate, admit, revert | A control that is simply blind | Anything you did not think to try |

Three limits are worth stating plainly, because each cost real time here:

**A validator only sees the documents you give it.** The pattern gate was green
while `sg-open` was blind to half the encodings of the API it watches.

**Configuration is not evidence.** GuardDuty's organization auto-enable read
`ALL` while the management account had no detector at all — the delegated
administrator cannot create one for that account, and nothing in the
configuration said so.

**A green suite can be green for the wrong reason.** The local EventBridge
evaluator in PontoAntiCrack is a reimplementation; a bug in it would have turned
every detection test green at once. It has its own tests, and it is checked
against the real service by a separate gate, because "our evaluator agrees with
our evaluator" is not a claim.

## 11. The honesty discipline, mechanised

Rules that are only written down stop being true within a month and nobody
notices. Where mechanisation was possible, these are enforced by a test:

- **Provenance markers on unverified data.** Every PontoAntiCrack fixture
  carries its status and the command that would capture the real event; every
  detection's metadata carries whether *all* its fixtures are verified. A test
  fails if a marker is missing, if status and flag disagree, or if the metadata
  contradicts the fixtures. Promoting a fixture means updating both places or CI
  fails. This gate fired three separate times during the final session and was
  right every time.
- **Negative tests are mandatory.** CI fails a pattern test with no
  `assert not matches`.
- **Suppressions carry reasons.** Every scanner skip has an inline
  justification, and where the finding is real, a threat-model ID and the stack
  that closes it.
- **Empty is a valid state.** `PontoAntiCrack/docs/evidence/` stayed empty for
  the entire build because nothing had been measured there, with a README saying
  what would land in it and what would produce each artefact. A table of
  realistic-looking latency numbers would have been trivial to write and would
  have made every other number in the portfolio worthless.
- **Limits stated in the strong form.** "SLSA Build L2, not L3." "No
  multi-tenant isolation is claimed." "100% means PASS/(PASS+FAIL)." "One
  detection, once, in one account."
- **Third-party CI actions pinned to commit SHAs**, not tags. A tag is mutable:
  whoever controls the action repository can repoint it at new code.

## 12. Cost, and the decision it forced

A hard shared ceiling of **USD 20/month** across AwLZ and PontoAntiCrack, with
budget alerts at 85% and 100% of actual plus 100% of forecast. KateClusters and
ProvenancePipeline cost nothing: a local VM and free-tier CI.

The lever was Security Hub. CIS v3.0.0 in all five accounts projected
**USD 24.77/month** jointly — over the ceiling. Retaining the benchmark in the
delegated security account alone projects **USD 13.73**. The five-account
configuration was kept alive only long enough to capture the control experiment,
then removed, and what was lost is stated: there is no longer a live per-account
CIS score.

Two related decisions:

- A dedicated key was added for the break-glass alarm topic, at roughly
  USD 1/month, because the AWS-managed alternative accepts no key policy and the
  alert announces that a recovery role was used — precisely what an attacker
  would want to read or suppress.
- The Lambda concurrency quota was requested at 1000, the lowest value AWS
  Service Quotas accepts. A concurrency quota is a ceiling rather than a charge,
  and reserved concurrency still caps the system at 15 simultaneous executions.
  The alternative — dropping the reservation to fit the existing quota of 10 —
  would have deleted the control that ADR-008 exists to provide.

## 13. Operating and verifying it from cold

Nothing below needs prior context.

```bash
pwsh scripts/status.ps1        # commits, cleanliness, visibility, evidence, demos
```

Without credentials:

```bash
cd ../PontoAntiCrack && make lint && make test && make coverage
cd ../KateClusters   && make validate
cd ../AwLZ           && terraform fmt -check -recursive && tflint --recursive
```

With an AWS session (`aws sso login --profile mgmt`; sessions last twelve hours
and should be ended explicitly):

```bash
cd ../PontoAntiCrack && make patterns          # every fixture through EventBridge itself
cd ../AwLZ && bash scripts/export-cis-score.sh # CIS per account, sanitized
```

Concrete account identifiers live only in gitignored `terraform.tfvars` and
`backend.hcl` files; the committed `example.*` files are the templates. To
recover the real values, read them back from Terraform outputs.

**Detonating an attack technique** is the only genuinely dangerous operation
here. It is confined to `awlz-lab` by two independent guards: the account ID is
printed and confirmed, and the assertion scripts refuse to run unless an
environment variable naming the lab account matches the resolved caller
identity.

The evidence directories are the point, and they are readable without running
anything at all.

## 14. What is open, deliberately

Not incompleteness. Each is a stated limit with the condition that would close
it, and a portfolio with no open gaps reads as dishonest, because real systems
have them.

| Open | Condition that closes it |
|---|---|
| A *busy* cost month | September 2026 closed at USD 7.31 — the first representative month, but a quiet one. Config and Security Hub bill on change, so a month with real Terraform activity is the unmeasured upper bound |
| `s3-public` and `iam-key-leak` undetonated | A lab session per technique; their latency is unmeasured and no number is claimed |
| ProvenancePipeline B5 / T9 | Pin cosign 2.x so enforcement stops depending on the repository staying public |
| SLSA Build L2, not L3 | Delegate provenance generation to an isolated context |
| Cluster-wide default-deny | A Calico `GlobalNetworkPolicy` |
| The Falco mining-port rule cannot fire behind blocked egress | An independent CPU-anomaly signal |
| No Rekor monitoring; no low-and-slow authorisation rule; no `ModifySecurityGroupRules` detection | Named in the threat models with their conditions |
| Three PontoAntiCrack roles without the AwLZ permissions boundary | The sibling owner adopts the boundary or records an exception; the SCP already governs anything created from now on |
| Slack delivery unproven | A webhook that does not exist yet; the audit table is the system of record |

## 15. If you only read four files

1. **`AwLZ/docs/evidence/scp-verification.md`** — what a control experiment
   looks like when the answer is "no effect", and why that is still the finding.
2. **`PontoAntiCrack/docs/evidence/detonation-sg-open.md`** — why a fully tested
   detection can be completely blind.
3. **`ProvenancePipeline/docs/architecture.md`, ADR-009** — an assumption that
   was exactly backwards, corrected in place with the original left visible.
4. **`KateClusters/docs/attack-detection/`** — four attack simulations with the
   alerts they actually produced, including the one that cannot fire.
