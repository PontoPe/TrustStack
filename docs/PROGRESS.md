# Program progress

Last updated: 2026-07-30.

## Current coordination state

The program now runs as one TrustStack overlooker plus one persistent owner per sibling.
`AGENTS.md` is the operating manual; `prompts/19-autonomous-overlooker.md` is the handoff
for the next overlooker.

### PontoAntiCrack

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

## Next concrete actions

1. Start the ProvenancePipeline VM phase; `AMBIENTE: kate LIBERADA` has been emitted.
2. Re-run the AwLZ C6 Cost Explorer query on or after `2026-08-02T12:00:00-03:00`. Do not
   relabel an estimate as an actual.
3. Present the PAC quota choice to the operator once, with recommendation and blast radius;
   leave PAC paused and stable until explicit authority changes. Hand the boundary finding
   above to that owner when it resumes.
4. After each owner result, verify repo/evidence/cleanup, then update ROADMAP, README and
   this file.
