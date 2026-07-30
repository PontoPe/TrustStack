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
| KateClusters | ✅ | ✅ | ❌ | ❌ | GIF, posture doc, go public |
| AwLZ | ✅ | partial | ❌ | ✅ | the CIS evidence it promises |
| PontoAntiCrack | written only | ❌ | ❌ | ❌ | everything that makes it real |

Regenerate with `pwsh scripts/status.ps1 -Markdown`. Never type these numbers by hand.

---

## A. Cross-cutting — overlooker does these

- [ ] **A1** AwLZ working tree is dirty on a public repo — the half-done handbook rename
      (`docs/project-handbook.md` deleted, `docs/AwLZ-handbook.md` untracked). Finish or revert.
- [ ] **A2** `AwLZ/live/security/` and `AwLZ/live/workload-dev/` hold only `.gitkeep`.
      Scaffold left over from before the real structure. Delete, or justify in a README.
- [ ] **A3** KateClusters has unpushed commits. Push.
- [ ] **A4** AwLZ is the only repo whose handoff lives outside it (Nextcloud `AwLZ-pres.md`).
      Bring a version in-repo; the traps section is the most reviewer-legible page the
      project produced and the public repo is missing it.
- [ ] **A5** KateClusters posture is imprecise: default-deny is **per namespace**, with no
      Calico `GlobalNetworkPolicy`, so a fresh namespace is fully open. The docs imply
      otherwise. Correct the docs and threat model; record `GlobalNetworkPolicy` as future
      work. *(Found by the ProvenancePipeline session installing Kyverno.)*
- [ ] **A6** `AlwaysPullImages` is enabled in KateClusters and undocumented there. Decide
      where the ADR lives and write it.
- [ ] **A7** Propagate `demo-record.sh` to AwLZ, KateClusters, PontoAntiCrack with a
      context-specific `DENY_PATTERNS`, and **test each deliberately** — an audit that never
      fires means a weak pattern list, not a clean recording.
- [ ] **A8** Contradiction sweep across the four repos: dead file paths, "blocked" states
      that have unblocked, stale ADR counts, "not built" about things now built.
- [ ] **A9** Keep `TrustStack/README.md` accurate — numbers generated, ADR-005 inversion and
      threat T9 reflected as active risk.
- [ ] **A10** Make the agent instructions vendor-neutral in all four sibling repos, the way
      `TrustStack/` now is: move the content of each `CLAUDE.md` into `AGENTS.md`, and leave
      `CLAUDE.md` and `AGENT.md` as one-line pointers. **Do not duplicate the content** — a
      second copy drifts. Do this inside each repo, under that repo's conventions, and run
      its validation before committing. Reason: the project should not be tied to one
      vendor's agent, and `AGENTS.md` is the name the widest range of tools reads.

## B. PontoAntiCrack — the long pole

Nothing here can be done by the overlooker: it needs `aws sso login`, which needs a browser.
**Write the prompts; hand them over.**

- [ ] **B1** Write the apply prompt. `make build` → plan → apply with `dry_run = true`.
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

**Do not go past B4 into B5 without B3.** Live remediation with unconfirmed patterns is a
system that may not fire, or may fire on the wrong resource, holding write access to AWS.

## C. AwLZ — evidence, not code

- [ ] **C1** Confirm GuardDuty member enrollment; `create-members` if auto-enable did not
      cover pre-existing accounts. The one control configured but never demonstrated.
- [ ] **C2** Decide the Security Hub cost lever (`auto_enable_standards`). **Before ~27 Aug.**
      Either accept a higher ceiling for the evidence, or turn it off and say so in
      `docs/cost.md`. Decide deliberately, not in response to a 100% budget alert.
- [ ] **C3** Capture the CIS baseline, then run the `awlz-lab` control-group experiment:
      detach the SCPs, score, reattach, score. **This is the headline evidence the README
      promises** and the honest replacement for the "before vs after" that is no longer
      obtainable.
- [ ] **C4** Permission boundaries + a Config rule for T5; a CloudWatch alarm on break-glass
      role assumption for T8. Both are open residual risks in the threat model.
- [ ] **C5** A read-only role per member account so `live/logging` and `live/detection` can
      rejoin the CI plan matrix.
- [ ] **C6** Cost actuals after a billing cycle.
- [ ] **C7** Demo GIF — the SCP denying from inside a member account is the strongest scene.

## D. KateClusters — nearly there

- [ ] **D1** Demo GIF. Terminal-native scenes: `kube-bench` delta, PSA rejecting with a real
      403, a Falco line firing. For the Grafana alert, query the API and show the state
      transition as JSON rather than screen-recording a browser — stronger evidence and
      re-recordable.
- [ ] **D2** Run CI once so kubescape and polaris stop being unverified.
- [ ] **D3** Repo public.

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

## Suggested order

Nothing below is blocked by anything else today.

```
A (overlooker, 1 session)
  ├─> D1, D2, D3        KateClusters — short
  ├─> B1..B8            PontoAntiCrack — the real remaining work, 3-4 sessions
  └─> C1..C7            AwLZ — 1-2 sessions plus a billing wait
```

Estimate: **7 to 9 repo sessions**, plus overlooker passes between them.
