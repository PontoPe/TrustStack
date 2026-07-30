# Overlook report — 2026-07-30

## Outcome

Cross-cutting queue A1–A10 is closed. All four sibling working trees are clean, pushed and
aligned with their upstream branch. No AWS apply, attack detonation, cluster mutation or
demo recording was performed by the overlooker.

## What was stale or contradictory

- AwLZ had a content-identical handbook rename half applied on a public working tree, two
  empty stack scaffolds and links to the deleted name.
- The AwLZ handoff already existed in-repo as the handbook content; the roadmap's claim that
  it existed only in Nextcloud was stale. SHA-256 equality was checked before merge.
- KateClusters still described itself as unbuilt in its README, agent instructions,
  handbook, attack docs and audit docs despite committed live evidence.
- KateClusters implied default-deny more broadly than Kubernetes NetworkPolicy provides.
  The five repo-owned namespaces are covered; a fresh namespace is open because no Calico
  `GlobalNetworkPolicy` exists.
- KateClusters already documented `AlwaysPullImages` in ADR-004 and kubeadm config. The
  roadmap, not the repo, was stale.
- The recorded `vmrun` path used `Program Files (x86)`; the executable is under
  `C:\Program Files\VMware\VMware Workstation\`.
- ProvenancePipeline retained an empty, superseded `policies/verify/` path and current docs
  still asked for its deletion.
- PontoAntiCrack's lock selected `hashicorp/aws 6.57.0`, which disappeared from the official
  registry. The signed replacement 6.57.1 was selected without changing the `~> 6.0`
  constraint.
- TrustStack still showed 39/19/29/15 commits, 49 ADRs, private GHCR, unbuilt Kyverno,
  unpushed Kate commits and an external-only AwLZ handoff.

## What changed

| Repo | Commit | Change |
|---|---|---|
| AwLZ | `c6002c4` (PR #8 merge) | handbook rename, empty scaffolds removed, in-repo handoff path, agent pointers, AWS-aware recording gate |
| ProvenancePipeline | `b04e72c` | vendor-neutral agent pointers, dead verify scaffold removed, references reconciled |
| KateClusters | `242b5e1` | live posture reconciled, namespace scope/residual risk explicit, recording gate, stale invariant message fixed |
| PontoAntiCrack | `9ac2bfe` | vendor-neutral agent pointers, PAC-aware recording gate, provider lock 6.57.1, handoff note |

All tracked Markdown local links pass. `AGENTS.md` is canonical in all four siblings;
`CLAUDE.md` and `AGENT.md` are one-line compatibility pointers.

Recording scripts in AwLZ, KateClusters and PontoAntiCrack passed Bash syntax, one
context-specific forbidden probe and one safe negative control. This proves the audit can
both fire and avoid a trivial false positive; it does not substitute for watching a future
GIF.

## Validation

- **AwLZ:** fmt, tflint, Trivy 0, Checkov 367 passed / 0 failed / 21 skipped, all six
  `terraform validate`; PR #8 then passed static, six validate and four real OIDC plan jobs.
- **ProvenancePipeline:** `go vet` + tests green. ShellCheck reported existing SC2294 in
  `scripts/demo.sh:31`; it was neither introduced nor suppressed.
- **KateClusters:** `make validate` green: invariants 9/9, ShellCheck clean, yamllint with
  its existing warnings, kubeconform 55 valid / 0 invalid / 3 skipped.
- **PontoAntiCrack:** Ruff, formatting, mypy, Trivy, Checkov 76/0/6, 167 pytest tests,
  detection coverage, build, tflint, ShellCheck, init and validate green.

Failed attempts worth retaining:

- `terraform -chdir=$path` does not expand in PowerShell. Use `Push-Location` or an explicit
  path.
- AwLZ `terraform init -backend=false` reused an existing backend cache and tried an expired
  SSO token. Direct `terraform validate` used the installed locked providers and passed.
- Native Windows `make coverage` cannot launch a `/usr/bin/env bash` shebang. Running the
  same script through Git Bash passed.

## Delegated deep work

- Prompts 08–10: PAC dry-run apply/pattern gate; real fixtures/dry-run detonations; live
  remediation/breaker/demo/publication.
- Prompts 11–13: AwLZ GuardDuty/cost/CIS; T5/T8 + read-only CI roles; demo + billing actuals.
- Prompt 14: KateClusters demo, real CI scanner run and public release.

These roadmap items remain open until those repo sessions produce command output. A written
prompt is not evidence.

## Remaining line of work

Start with prompt 08. Do not proceed past PAC's pattern gate if any authoritative result is
`false`, and do not enable live remediation before all fixtures come from observed
CloudTrail events. AwLZ C2 must be decided before the GuardDuty trial ends around
2026-08-27.
