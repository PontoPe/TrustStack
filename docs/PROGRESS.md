# Program progress

Last updated: 2026-08-15, after a live verification pass.

## Current coordination state

The program now runs as one TrustStack overlooker plus one persistent owner per sibling.
`AGENTS.md` is the operating manual; `prompts/19-autonomous-overlooker.md` is the handoff
for the next overlooker.

### PontoAntiCrack

- **B1–B8 complete; the repository is public.** The layer meets the definition of finished.
- The Lambda concurrency quota was requested at 1000 and granted, which unblocked the
  deferred wiring: 12 creates, 3 updates, no drift.
- `make patterns`: seventeen fixtures, zero disagreements with EventBridge. Fifteen of
  seventeen fixtures are recorded events.
- `sg-open` detonated with Stratus Red Team v2.34.1. Live remediation revoked the
  world-open SSH rule **5.97 s** after the attacker's API call and left port 443 alone;
  the dry run before it changed nothing; the circuit breaker held after five actions.
- Detonating found two defects that 176 green tests and a passing pattern gate had missed:
  a loop guard reading the caller-chosen session name, so any attacker passing
  `--role-session-name pac-…` was skipped; and a pattern that knew only one of the two
  CloudTrail encodings of `AuthorizeSecurityGroupIngress`. Both fixed and written up.
- CI was also repaired before any of this: two shell gates were mode 644, so every run
  exited 126 before a gate executed, and `aquasecurity/trivy-action@0.28.0` had stopped
  resolving.
- The lab is clean and history was scrubbed of the lab account ID before publication.
- Not claimed: `s3-public` and `iam-key-leak` were not detonated, so their remediation
  latency is unmeasured; the Slack path is unproven because no webhook exists.

### KateClusters

- Owner reported D1–D3 complete and emitted `AMBIENTE: kate LIBERADA`.
- Demo recorded (`docs/img/demo.gif` and `.cast`), CI green 5/5 on `main`, PR #1 merged,
  repository public with 123/123 links valid, history rewritten and rescanned across 38
  commits, tree clean and cluster healthy.
- The VM lease is released, so the ProvenancePipeline VM phase is unblocked.

### AwLZ

- C1–C5 and C7 are proved and merged through protected PR #11; `main` is synced and the
  tree is clean. Only C6 remains and it is blocked on time, not on work.
- C1: the management account had no regional GuardDuty detector, which is why delegated
  auto-enable never reached it. Detector is Terraform-managed; four members `Enabled`.
- C2: the cost lever is applied. CIS v3.0.0 stays in `awlz-security` only and future-account
  auto-enable is `NONE`, moving the conservative joint projection from USD 24.77 to
  USD 13.73 against the USD 20 ceiling. A dedicated CMK for the break-glass topic accounts
  for USD 1 of that.
- C3: the lab control experiment ran and reversed inside a 5m20s window, with `awlz-dev`
  kept continuously protected by attaching the policies to it before they left the OU. The
  published result is negative and honest — the CIS score is identical control by control
  with and without the SCPs, because no CIS control reads an SCP. Probes flipped denied →
  allowed → denied, and reattachment was verified independently and by plan.
- C4: boundaries, the Config rule and the `require-permissions-boundary` SCP are live. The
  T8 alarm reached `ALARM` on real recovery-role assumptions. The Config rule immediately
  found three PontoAntiCrack remediation roles in `awlz-lab` without a boundary; they were
  reported, not modified.
- C5: `awlz-gha-plan-readonly` per member account; all six stacks plan green in CI through
  OIDC with no administrator anywhere.
- C6: **closed 2026-08-04.** The July window returned `Estimated: false`. Gross usage
  USD 1.4830, credits covered all of it, August run rate USD 6.38/month against the USD 20
  ceiling. Reported gross; the zero invoice would understate the model by its whole subject.
- `awlz-lab` is released: all four SCPs are attached to both OUs, no direct attachments
  remain, and no plan, apply or experiment is in flight.

### ProvenancePipeline

- Baseline remains complete, evidenced, demonstrated and public.
- Prompt 18 may do local/CI audit, but any VM work waits for
  `AMBIENTE: kate LIBERADA`.

### Open finding across owners

The AwLZ boundary Config rule reports `pac-sg-open-remediation`,
`pac-s3-public-remediation` and `pac-iam-key-leak-remediation` in `awlz-lab` as
`NON_COMPLIANT`: they were created before the boundary existed. Nothing is broken — the
preventive SCP only governs roles created from now on — but the PontoAntiCrack owner
should decide whether to adopt the boundary or record an exception.

### Verification pass — 2026-08-15

Three live checks, all against AWS rather than against a document.

- **Lambda quota** `L-B99A9384`: `CASE_CLOSED`, granted 47 minutes after it was raised.
  Applied and effective value 1000.
- **Budget**: USD 3.093 actual against the USD 20 ceiling, 15%. No threshold fired; alerts
  remain at 85% and 100% of actual plus 100% of forecast. August 1–15 gross usage is
  USD 2.8364, so the run rate projected from three days held.
- **GuardDuty sample findings** from the fixture capture were still unarchived sixteen days
  on, two at severity 8. Now archived; zero unarchived findings organization-wide.

Two things fell out of those checks that were not being looked for. AWS Config billed 300×
less in August than in July, which reads like a stopped recorder and is instead the
difference between first-time capture and steady state — all five recorders verified
`recording: true` / `SUCCESS`. And a member account **cannot** archive its own GuardDuty
findings when a delegated administrator exists, so taking a member account does not let an
attacker clear the evidence about it. Both are written up in AwLZ.

PontoAntiCrack has run with live remediation for sixteen days and its audit table holds the
same ten records it held on 2026-07-31 — zero remediations, zero false positives, against an
otherwise idle account.

## What finishing the program now requires

**All four layers meet the definition of finished** — code applied to real infrastructure,
real artefacts in `docs/evidence/`, a demo with its cast, a threat model whose residual
risks are stated, and a public repository.

The last dated item closed on 2026-08-04. **Nothing in the program is open on a deadline.**

What replaced it is maintenance rather than work, and it lives in
[ROADMAP.md § Maintenance](ROADMAP.md#maintenance--what-goes-stale-where-and-what-refreshes-it):
clock-driven items (September 2026 is the first cost month with neither credits nor service
trials), condition-driven items (the revisit conditions in the program threat model), and
drift-driven items (counts, pinned versions, action SHAs, base image digests).

Optional and explicitly not required to finish: ProvenancePipeline **E1** (breaking the
dependency on repository visibility by pinning cosign 2.x), and detonating PontoAntiCrack's
other two techniques so `s3-public` and `iam-key-leak` get measured latencies too.

## Next concrete actions

1. On or after 2026-09-01, re-run the AwLZ cost query for the August window — the first
   month with neither credits nor service trials, and therefore the first representative
   one. Use the `RECORD_TYPE` filter; without it credits net usage to zero and a healthy
   Config recorder reads as USD 0.
2. Optional: detonate `s3-public` and `iam-key-leak` to measure their remediation latency.
   The pattern gate and captured fixtures cover them; only the live number is missing.
3. Optional: close ProvenancePipeline E1.
4. Decide the PontoAntiCrack boundary finding: the AwLZ Config rule reports three
   `pac-*-remediation` roles in `awlz-lab` as `NON_COMPLIANT` because they predate the
   permissions boundary. Adopt the boundary or record an exception; the preventive SCP
   already governs anything created from now on.
