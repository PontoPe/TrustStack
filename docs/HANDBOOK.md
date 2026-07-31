# TrustStack — the program handbook

The definitive account of the whole portfolio: what was built across four
repositories, how the layers depend on each other, what each one proved and by
what method, what proving them actually found, and what is deliberately still
open.

Written **2026-07-30**, the day the last layer closed. Every number here was
read out of a repository or a command.

| Document | Answers |
|---|---|
| **HANDBOOK.md** (this file) | What the program is, how it was proved, and what it cost to prove |
| [README.md](../README.md) | The portfolio-facing summary |
| [ROADMAP.md](ROADMAP.md) | Item-by-item state, A–E |
| [PROGRESS.md](PROGRESS.md) | Where the last session stopped |
| [AGENTS.md](../AGENTS.md) | Operating manual for whoever works on it next |

Each sibling repository has its own handbook for its own layer. This one does
not repeat them; it covers what is only visible from above.

---

## 1. The thesis, and the rule that follows from it

Four repositories, one claim per layer:

| Layer | Question | Repository |
|---|---|---|
| Cloud governance | Can an account do something nobody watches? | **AwLZ** |
| Artifact provenance | Do I know where this container came from? | **ProvenancePipeline** |
| Runtime | If something breaks in, does anyone find out? | **KateClusters** |
| Response | When something is found, what happens automatically? | **PontoAntiCrack** |

> **The deliverable is not working infrastructure. It is reproducible
> infrastructure plus evidence that the controls do what the documentation
> claims — including where they don't.**

Anyone can apply a Terraform module or install a Helm chart. The part worth
showing is `docs/evidence/`, and the part worth showing *there* is the entries
that record a control failing, a claim being wrong, or a number coming back
worse than expected.

That rule has a cost, and the cost is the point. Three of the four layers had
to publish a result that was less flattering than the one originally promised.

## 2. Final state

| Repository | Commits | Public | Applied to | Evidence | Demo |
|---|---:|---|---|---:|---|
| **AwLZ** | 69 | ✅ | a live 5-account AWS organization | 5 | ✅ |
| **PontoAntiCrack** | 38 | ✅ | the isolated `awlz-lab` account | 5 | ✅ |
| **KateClusters** | 43 | ✅ | a live single-node cluster on a VM | 2 | ✅ |
| **ProvenancePipeline** | 24 | ✅ | GHCR + the KateClusters cluster | 2 | ✅ |

56 ADRs across the four.

The definition of finished, agreed before the work started: code applied to real
infrastructure, real artefacts in `docs/evidence/`, a demo GIF with its cast, a
threat model whose residual risks are stated rather than implied, and a public
repository. **All four layers meet it.**

One item remains open in the whole program: AwLZ **C6**, cost actuals. Cost
Explorer still returns `Estimated: true` for every day this organization has
existed, so the earliest defensible query is `2026-08-02`. That is a billing
window, not work, and inventing the number would have been the single cheapest
way to discredit everything else here.

## 3. How the layers actually couple

Two real dependencies, both one-directional, and both exercised rather than
diagrammed.

**PontoAntiCrack consumes AwLZ.** The organization CloudTrail it reads and the
lab account it detonates in are AwLZ resources. It could not be meaningfully
built before AwLZ's logging existed. In the end the coupling ran both ways in
practice: AwLZ's permissions-boundary Config rule, applied hours earlier,
immediately reported three PontoAntiCrack roles that predate it — a real finding
handed to the sibling owner rather than silently fixed across a repository
boundary.

**ProvenancePipeline enforces on KateClusters.** The Kyverno policy belongs to
ProvenancePipeline; the cluster it admits into belongs to KateClusters. One
signed image is admitted and three unsigned paths are refused, on video.

Nothing else couples. AwLZ and KateClusters were built in parallel on purpose:
a portfolio where every piece needs every other piece is a portfolio that cannot
be reviewed one repository at a time.

## 4. What proving each layer actually found

This is the section that justifies the method. Every one of these was invisible
to a green test suite.

### AwLZ — the headline evidence came back negative

The README promised a CIS score "before vs after" the guardrails. That was not
obtainable: the guardrails went in before Security Hub did, so no un-hardened
"before" existed organization-wide. The honest replacement was a control
experiment on the throwaway account — measure `awlz-lab` with its SCPs, remove
them from that account only, measure again, put them back.

The result: **all 35 controls identical in both states.** No CIS v3.0.0 control
reads a service control policy. A benchmark score describes resource
configuration; it cannot describe a preventive guardrail. Reporting the score as
evidence that the SCPs work — which the original README implied — was measuring
the wrong thing entirely.

What does show the guardrails working is behavioural: `ec2:DescribeVpcs` in a
denied region and `cloudtrail:StopLogging` on a trail that does not exist, both
explicitly denied, then allowed during the window, then denied again. Both
probes name resources that do not exist, so nothing was created or destroyed to
produce the evidence.

The experiment also had to be designed so that only the lab lost protection. The
SCPs sit on an OU that also holds `awlz-dev`, so they were attached directly to
`awlz-dev` before leaving the OU and removed only after returning. `awlz-dev`'s
effective policy never changed, and reattachment ran from a shell trap so it
would have happened even if the measurement had crashed.

### PontoAntiCrack — the detection was fully tested and completely blind

Before the first detonation: 176 passing tests, a coverage gate that fails any
pattern without a negative assertion, a gate that replays every fixture through
EventBridge itself and got fifteen agreements, and fifteen of seventeen fixtures
captured from real CloudTrail rather than written from documentation.

Detonating the technique found two defects anyway.

**A loop guard the attacker chooses.** The runtime dropped events whose
principal ARN contained `pac-`, to stop a remediation re-triggering its own
detection. An assumed-role ARN is
`arn:aws:sts::<account>:assumed-role/<role>/<session>`, and the session name is
set freely by the caller on every `AssumeRole`. Stratus Red Team happened to run
under a session called `pac-terraform`, so the detection classified the attack
as its own automation and wrote a confident `SKIPPED`. Anyone passing
`--role-session-name pac-anything` was invisible.

**A pattern that knew one of two encodings.** `AuthorizeSecurityGroupIngress`
is recorded two different ways by CloudTrail. The AWS CLI sends `IpPermissions`
and the record nests `ipPermissions.items[].ipRanges.items[].cidrIp`. A caller
using the legacy top-level parameters produces an empty `ipPermissions` with
`ipProtocol`, `fromPort`, `toPort` and `cidrIp` directly on `requestParameters`.
Every fixture in the repository had been produced by the CLI, so the pattern had
only ever seen one shape. Port 22 was opened to the internet and the rule did
not match — the only thing that matched was the technique's own Terraform
warm-up creating a 443 rule.

Both generalise past this project:

- A security decision made from a field the adversary sets is not a control.
  Ask of any predicate: *who writes this string?*
- Fixtures inherit the bias of whatever produced them. Two tools calling the
  same API are two sources of truth, and a corpus built from one has a blind
  spot invisible from inside it.

After the fixes, the measured result: **5.97 seconds** from the attacker's API
call to the world-open SSH rule being revoked, with the group's port 443 rule
left alone. The dry run before it produced the same plan and the same snapshot
and changed nothing.

### KateClusters — the posture claim was broader than the mechanism

The repository described default-deny networking. Kubernetes NetworkPolicy is
namespace-scoped, so the five repo-owned namespaces were covered and a newly
created namespace was fully open, because no Calico `GlobalNetworkPolicy`
existed. The documents now say exactly that and record cluster-wide default-deny
as the closing condition.

Also worth keeping: one Falco rule cannot fire when egress is already blocked,
because the rule needs an established socket. Prevention and detection are not
independent there, and pretending otherwise would have double-counted a control.

### ProvenancePipeline — the assumption was exactly backwards

ADR-005 said the cosign `slsaprovenance1` attestation is the copy the cluster
enforces and GitHub's is the one it cannot see. On GHCR it is the reverse.
Discovering that required building the cluster half; the correction is ADR-009,
and the handoff carries a warning at the top pointing at the paragraph to
distrust in any stale copy.

## 5. The method, and where it runs out

Each repository runs its own gate stack. The pattern that emerged across all
four is a ladder, and every rung catches a class the one below it cannot:

| Rung | Example | Catches | Cannot catch |
|---|---|---|---|
| Static | `ruff`, `mypy`, `tflint`, `checkov`, `trivy`, `kubeconform` | Malformed, unsafe, drifted | Anything about behaviour |
| Unit | `pytest` with fixtures, `cfn-guard` cases | Wrong logic against a document you wrote | A document that does not match reality |
| Service | `terraform plan`, `aws events test-event-pattern`, `terraform validate` against real state | Disagreement between your model and the provider | A shape you never handed it |
| Live | apply, detonate, admit, revert | A control that is simply blind | Anything you did not think to try |

Three limits are worth stating plainly, because each cost real time here:

**A validator only sees the documents you give it.** The pattern gate was green
while `sg-open` was blind to half the encodings of the API it watches.

**Configuration is not evidence.** GuardDuty auto-enable read `ALL` while the
management account had no detector at all — the delegated administrator cannot
create one, and nothing in the configuration said so.

**A green suite can be green for the wrong reason.** The local EventBridge
evaluator in PontoAntiCrack is a reimplementation; a bug in it would have turned
every detection test green simultaneously. It has its own tests, and it is
checked against the real service by a separate gate, because "our evaluator
agrees with our evaluator" is not a claim.

## 6. The honesty discipline, mechanised

Rules that are only written down stop being true within a month and nobody
notices. Where mechanisation was possible, these are enforced by a test:

- **Provenance markers on unverified data.** Every PontoAntiCrack fixture
  carries its status and the command that would capture the real event; every
  detection's metadata carries whether *all* its fixtures are verified. A test
  fails if a marker is missing, if status and flag disagree, or if the metadata
  contradicts the fixtures. Promoting a fixture means updating both places or CI
  fails. This gate fired three separate times during the final session and was
  right every time.
- **Negative tests are mandatory.** A pattern tested only for what it catches
  matches everything, forever, silently. CI fails a pattern test with no
  `assert not matches`.
- **Suppressions carry reasons.** Every scanner skip has an inline
  justification, and where the finding is real, a threat-model ID and the stack
  that closes it.
- **Empty is a valid state.** `PontoAntiCrack/docs/evidence/` stayed empty for
  the entire build because nothing had been measured there, with a README
  explaining what would land in it and what would produce each artefact. A table
  of realistic-looking latency numbers would have been trivial to write and
  would have made every other number in the portfolio worthless.
- **Limits stated in the strong form.** "SLSA Build L2, not L3." "No
  multi-tenant isolation is claimed." "100% means PASS/(PASS+FAIL)." "One
  detection, once, in one account."

## 7. Cost, and the decision it forced

A hard shared ceiling of **USD 20/month** across AwLZ and PontoAntiCrack, with
budget alerts at 85% and 100% of actual plus 100% of forecast.

The lever was Security Hub. CIS v3.0.0 in all five accounts projected
**USD 24.77/month** jointly — over the ceiling. Retaining the benchmark in the
delegated security account alone projects **USD 13.73**. The five-account
configuration was kept alive only long enough to capture the C3 control
experiment, then removed, and what was lost is stated: there is no longer a live
per-account CIS score.

Two related decisions worth recording:

- A dedicated CMK was added for the break-glass alarm topic, at roughly
  USD 1/month, because `alias/aws/sns` accepts no key policy and the alert
  announces that a recovery role was used — precisely what an attacker would
  want to read or suppress.
- The Lambda concurrency quota was requested at 1000, the lowest value Service
  Quotas accepts. A concurrency quota is a ceiling rather than a charge, and
  `reserved_concurrency = 5` still caps the system at 15 concurrent executions.
  The alternative — dropping the reservation to fit the existing quota — would
  have deleted the control that ADR-008 exists to provide.

## 8. Verifying this from cold

Nothing below needs prior context.

```bash
pwsh scripts/status.ps1        # commits, cleanliness, visibility, evidence, demos
```

Per repository, without credentials:

```bash
cd ../PontoAntiCrack && make lint && make test && make coverage
cd ../KateClusters   && make validate
cd ../AwLZ           && terraform fmt -check -recursive && tflint --recursive
```

With an AWS session:

```bash
cd ../PontoAntiCrack && make patterns          # every fixture through EventBridge itself
cd ../AwLZ && bash scripts/export-cis-score.sh # CIS per account, sanitized
```

The evidence directories are the point, and they are readable without running
anything:

- `AwLZ/docs/evidence/scp-verification.md` — every SCP probed from inside a
  member account, plus the lab control experiment and its null result.
- `PontoAntiCrack/docs/evidence/detonation-sg-open.md` — the two defects a
  detonation found that every green gate had missed.
- `PontoAntiCrack/docs/evidence/time-to-remediate.md` — 5.97 s, and everything
  that number does not cover.
- `KateClusters/docs/cis-results.md` — 12 FAIL to 0, generated from two committed
  `kube-bench` runs.

## 9. What is open, deliberately

Not incompleteness. Each is a stated limit with the condition that would close
it, and a portfolio with no open gaps reads as dishonest because real systems
have them.

| Open | Condition that closes it |
|---|---|
| AwLZ cost actuals (C6) | A closed Cost Explorer window; earliest 2026-08-02 |
| `s3-public` and `iam-key-leak` undetonated | A lab session per technique; their latency is unmeasured and no number is claimed |
| ProvenancePipeline B5/T9 | Pin cosign 2.x so enforcement stops depending on the repository staying public |
| SLSA Build L2, not L3 | Delegate provenance generation to an isolated context |
| Cluster-wide default-deny | A Calico `GlobalNetworkPolicy`; namespace policies cover the five owned namespaces |
| No Rekor monitoring, no low-and-slow authz rule, no CPU-anomaly signal | Named in the threat models with their conditions |
| Three PontoAntiCrack roles without the AwLZ permissions boundary | The sibling owner adopts the boundary or records an exception; the SCP already governs anything created from now on |

## 10. If you read four files

1. `AwLZ/docs/evidence/scp-verification.md` — what a control experiment looks
   like when the answer is "no effect", and why that is still the finding.
2. `PontoAntiCrack/docs/evidence/detonation-sg-open.md` — why a fully tested
   detection can be completely blind.
3. `ProvenancePipeline/docs/architecture.md` ADR-009 — an assumption that was
   exactly backwards, corrected in place with the original left visible.
4. `KateClusters/docs/attack-detection/` — four attack simulations with the
   alerts they actually produced, including the one that cannot fire.
