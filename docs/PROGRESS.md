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

- Owner is active on `codex/release-d1-d3`; VM `kate` remains leased.
- Recovery snapshot/revert was proved. Cluster returned healthy.
- A real Falco false-positive regression was fixed and verified against both benign
  runtime behavior and the escape signal; commit `875c915` is pushed.
- Deterministic demo driver is now in progress. Current uncommitted demo files belong to
  the active owner and must not be touched by the overlooker.

### AwLZ

- No owner task is active at this snapshot.
- `awlz-lab` is released, so prompt 16 may start immediately.

### ProvenancePipeline

- Baseline remains complete, evidenced, demonstrated and public.
- Prompt 18 may do local/CI audit, but any VM work waits for
  `AMBIENTE: kate LIBERADA`.

## Next concrete actions

1. Start or steer the AwLZ owner with `prompts/16-awlz-autonomous-owner.md`.
2. Monitor Kate without touching its worktree. On `AMBIENTE: kate LIBERADA`, start the
   Provenance owner VM phase.
3. Present the PAC quota choice to the operator once, with recommendation and blast radius;
   leave PAC paused and stable until explicit authority changes.
4. After each owner result, verify repo/evidence/cleanup, then update ROADMAP, README and
   this file.
