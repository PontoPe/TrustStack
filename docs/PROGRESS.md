# Program progress

Last updated: 2026-07-30.

## Current coordination state

The program now runs as one TrustStack overlooker plus one persistent owner per sibling.
`AGENTS.md` is the operating manual; `prompts/19-autonomous-overlooker.md` is the handoff
for the next overlooker.

### PontoAntiCrack

- CI was red on every push and neither cause was the quota: two shell gates were
  committed mode 644, so the runner exited 126 before any gate ran, and
  `aquasecurity/trivy-action@0.28.0` had stopped resolving. Both fixed; CI is green at
  PAC `e796ecf`. The consequence worth noting is that the gate refusing a detection
  without a negative test had never actually executed in CI.
- `make patterns` now runs the B2 gate in one command against all fifteen fixtures.

- Owner completed recovery and emitted `AMBIENTE: awlz-lab LIBERADO`.
- B1 is partially applied, not complete. Terraform tracks 31 stable resources, including
  three Lambdas in `lab` with `dry_run=true`; zero EventBridge targets and zero taints.
- Stratus v2.34.1 integrity passed and all 99 techniques are `COLD`. No technique ran.
- Lambda quota applied is 10. PAC needs 25 to keep 10 unreserved while reserving 5 for each
  function. API and console reject 25 because their request minimum is the formal default
  1000; no quota request exists.
- Fix and handoff commits `5deef0b` and `86067a7` are pushed; PAC tree is clean.
- Required operator decision: authorize a request for 1000 or choose another
  AWS-supported path. Removing/reducing `reserved_concurrency = 5` is prohibited.

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
- C6: earliest defensible Cost Explorer retry is `2026-08-02T12:00:00-03:00`, and only if
  the API stops returning `Estimated: true`.
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

## What finishing the program now requires

Three of the four layers meet the definition of finished. PontoAntiCrack is the whole
remaining program, and it is not blocked as thoroughly as the previous handoff implied.

| Step | Needs the Lambda quota? | Needs an AWS session? |
|---|---|---|
| B2 — `test-event-pattern` on 3 patterns × 15 fixtures | no | yes |
| B3 — capture real CloudTrail events, replace fixtures, re-run suite | no | yes |
| B4 — Stratus detonation with `dry_run=true`, assert alert | **yes** | yes |
| B5–B6 — live remediation, time-to-remediate, circuit breaker | **yes** | yes |
| B7–B8 — evidence, demo, publication | no | only to regenerate evidence |

B2 is the gate that carries the most risk in the whole portfolio: three load-bearing
assumptions about CloudTrail event shape die there, and no unit test can settle them
because the authoritative evaluator is the EventBridge service itself. It costs nothing,
mutates nothing, and does not need the quota. It should be the first thing run.

The quota blocks only the wiring: three Lambdas reserving 5 each, plus the 10 unreserved
executions AWS enforces, needs an applied quota of 25 in `sa-east-1`. The applied value is
10 and Service Quotas refuses any request below the formal default of 1000. Reducing or
removing `reserved_concurrency = 5` would close this by deleting the control ADR-008
exists to provide, and is prohibited.

## Next concrete actions

1. Start the ProvenancePipeline VM phase; `AMBIENTE: kate LIBERADA` has been emitted.
2. Re-run the AwLZ C6 Cost Explorer query on or after `2026-08-02T12:00:00-03:00`. Do not
   relabel an estimate as an actual.
3. **Decided 2026-07-30: submit `L-B99A9384` in `sa-east-1` for 1000.** The operator
   approved the recommendation; the request itself still needs an AWS session. A concurrency quota is a
   ceiling, not a charge; `reserved_concurrency = 5` still caps PAC at 15 concurrent
   executions, and the lab account runs nothing else that scales. The alternatives are worse:
   Premium Support costs money, and dropping the reservation deletes the control ADR-008
   exists to provide. Hand the AwLZ boundary finding above to that owner when it resumes.
4. After each owner result, verify repo/evidence/cleanup, then update ROADMAP, README and
   this file.
