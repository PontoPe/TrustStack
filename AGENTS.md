# TrustStack — context for coding agents

Canonical instructions for any agent working in this directory, whatever tool you are.
`AGENT.md` and `CLAUDE.md` are one-line pointers to this file so nothing has to be kept in
sync twice.

This directory manages a four-repository portfolio. It contains **no infrastructure code of
its own** and never will.

## What lives here

| Path | What it is |
|---|---|
| `README.md` | The portfolio handbook — thesis, status, how the repos interlock, findings, cost |
| `docs/ROADMAP.md` | **The durable plan.** What is left, what is done, and what is deliberately not being closed |
| `docs/HANDBOOK.md` | The program-level account: how the layers couple, what proving each one found, what is open on purpose |
| `docs/PROGRESS.md` | Where the last session stopped, if it stopped mid-item |
| `prompts/` | The session prompts that built each repo, archived and reusable |
| `scripts/status.ps1` | Reads the four repos and reports their real state |

The four repositories are **siblings**, not children: `../AwLZ`, `../ProvenancePipeline`,
`../KateClusters`, `../PontoAntiCrack`. Each is its own git repository with its own agent
instructions, handoff, ADRs and threat model.

## Start every session here

1. `docs/ROADMAP.md` — what remains.
2. `pwsh scripts/status.ps1` — the real state. **If the roadmap and a repo disagree, the repo
   is right.** Fix the roadmap.
3. `docs/PROGRESS.md` — if a previous session stopped mid-item.

Never assume a clean start. An item marked done is not redone; confirm it still holds with a
command, then move on.

## Operating model: one overlooker, four owners

The program uses five persistent Codex tasks. They are peer tasks in the app; the hierarchy
below is an operating agreement, not an automatic parent/child relationship.

| Task | Working directory | Durable brief | Responsibility |
|---|---|---|---|
| **Overlooker** | `TrustStack/` | this file + `docs/ROADMAP.md` + `docs/PROGRESS.md` | Coordinate the whole program, inspect owner progress, issue narrow steers, keep claims honest and decide what needs the operator |
| **PAC owner** | `PontoAntiCrack/` | `prompts/15-pac-autonomous-owner.md` | B1–B8: deploy in the lab, prove patterns and fixtures, dry-run/live remediation, breaker, evidence, demo, publication |
| **AwLZ owner** | `AwLZ/` | `prompts/16-awlz-autonomous-owner.md` | C1–C7: GuardDuty/CIS/cost evidence, T5/T8, least-privilege CI, demo |
| **Kate owner** | `KateClusters/` | `prompts/17-kate-autonomous-owner.md` | D1–D3: recoverable demo, real CI, public release |
| **Provenance owner** | `ProvenancePipeline/` | `prompts/18-provenance-autonomous-owner.md` | Preserve the finished baseline, audit it and attempt B5/T9 without weakening admission |

`prompts/19-autonomous-overlooker.md` is the entrypoint for a new overlooker. The numbered
phase prompts 08–14 remain historical detail; owner prompts 15–18 supersede manual handoffs
between those phases.

### Repo owner contract

An owner works only inside its repository. It must:

1. Re-enter from `AGENTS.md`, the repo handoff, `docs/PROGRESS.md`, git status/log and real
   infrastructure state. Never redo a proof merely because a new task started.
2. Continue across all authorized phases without asking for routine confirmation and
   without treating a commit, context compaction or completed phase as a stopping point.
3. Update `docs/PROGRESS.md` after every material gate with command, observed result,
   cleanup state and exact next action.
4. Keep commits small, Conventional, authored as `heavensnipe@gmail.com`, with no
   `Co-Authored-By`. Push completed steps and never finish with an unexplained dirty tree.
5. Announce before a live mutation, then report observed state rather than intention.
6. On a failure: stop the unsafe action, recover/clean first, inspect read-only, preserve
   useful local work, document, validate, commit/push, and release the shared environment
   if it is genuinely stable.
7. Never modify a sibling. Reading the shared demo recipe is allowed; writing there is not.

### What every owner reports

Commentary stays terse: current gate, live action about to happen, divergence, recovery and
the next gate. The final report must make these fields answerable without reading the whole
task:

```text
OWNER: <repo>
STATE: RUNNING | WAITING | BLOCKED | DONE
PROVED: <real commands/evidence>
CHANGED: <files, resources, commits/PRs>
VALIDATION: <tests and gates with real counts>
ENVIRONMENT: <stable state and cleanup>
BLOCKER: NONE | <exact blocker>
NEXT: <one concrete action>
USER ACTION: NONE | <one exact decision/action>
```

For shared live environments, the last line after that report is mandatory:

- PAC/AwLZ: `AMBIENTE: awlz-lab LIBERADO` or
  `AMBIENTE: awlz-lab NÃO LIBERADO — <motivo>`.
- Kate/Provenance: `AMBIENTE: kate LIBERADA` or
  `AMBIENTE: kate NÃO LIBERADA — <motivo>`.

Stopping, waiting or reaching a blocker does not itself release an environment.

## Shared-environment leases

Two pairs serialize live work:

| Environment | Owners | Rule |
|---|---|---|
| AWS account `awlz-lab` | PAC, AwLZ | Only one may plan/apply/detonate/detach SCPs at a time |
| VM `kate` | Kate, Provenance | Only one may snapshot/revert/apply/simulate/record at a time |

An owner may do local work while the other holds the lease. A new live phase starts only
after the previous owner emits the exact `LIBERADO` marker and the overlooker verifies that
the repo progress agrees. Silence is not a lease release.

## The overlooker control loop

The overlooker is a program manager with read access across all five directories. It does
not bring up a cluster, apply a stack, detonate an attack or record a demo itself.

Every overlooker turn:

1. Read this file, `docs/ROADMAP.md`, `docs/PROGRESS.md`, then run
   `pwsh scripts/status.ps1`.
2. Inspect active Codex tasks when task tools are available (`list_threads`, then
   `read_thread`). Task titles/summaries are hints, not evidence; confirm important claims
   from repo state and committed evidence.
3. Reconcile ROADMAP/PROGRESS with each owner repo. Do not write into a worktree that an
   active owner is changing.
4. Maintain the two environment leases. Start or steer the next owner only when its live
   environment is released; otherwise assign local-only work or wait.
5. When an owner returns a recoverable STOP, investigate with read-only checks and send a
   narrow steer that preserves its current work. Do not restart the owner or resend the
   whole prompt unless its contract is genuinely obsolete.
6. When an owner finishes, inspect its progress, commits, evidence, gates, cleanup and
   public claim. Only then update this repo's ROADMAP, README and PROGRESS.
7. Keep the program moving until only a true operator intervention or time-bound external
   wait remains.

If the overlooker must write a cross-cutting correction into a sibling:

> **Before writing, read that repo's agent instructions and handoff, obey its conventions,
> and run its validation entrypoint. Commit inside that repo with its author convention.
> Never make a commit that spans repositories. Never overwrite or clean up an active
> owner's uncommitted work.**

## Minimizing operator intervention

The overlooker and owners decide and execute without asking for:

- read-only inspection, diagnosis, tests, scans and evidence capture;
- safe fixes inside accepted ADRs;
- commits, push, protected PRs, waiting for CI and merging after all required checks pass;
- already-authorized lab/VM applies, simulations, cleanup, demo recording and publication;
- installing a required tool from an official release after integrity verification;
- retrying reversible operations after fixing the observed cause;
- documenting an honest negative result or leaving a declared residual risk open.

Ask the operator **once, with one concrete recommendation**, only when completion needs:

- interactive authentication that the task cannot complete from the existing session;
- an external secret or credential that does not exist, such as a Slack webhook;
- payment, Premium Support, a new account, root action or a cost ceiling above USD 20/month;
- an irreversible/destructive action outside the named lab/VM or a production resource;
- authority materially broader than the owner prompt;
- a central ADR/trust-model choice with no clearly safer reversible option;
- response to a secret exposure that requires the operator to revoke or rotate something
  the agent cannot;
- an external quota/provider decision whose official self-service paths are exhausted.

An intervention request contains: observed fact, attempts already made, safest
recommendation, exact blast radius/cost, and the one approval or action required. Never ask
the operator to run diagnostics the agent can run itself.

## Current program snapshot — refresh before relying on it

Observed 2026-07-30. This section is orientation only; owner `docs/PROGRESS.md` and live
state win if it becomes stale.

- **PAC:** B1 is partially applied and B2 is blocked. Terraform tracks 31 stable resources:
  three Lambdas are `Active/Successful`, `lab`, `dry_run=true`, with zero EventBridge
  targets and zero taints. Stratus v2.34.1 was integrity-verified and all 99 techniques are
  `COLD`. The account Lambda quota is 10; reserving 5 for each of three functions needs 25.
  Both API and console reject a request for 25 because the formal request minimum is 1000.
  No request was submitted. Commits `5deef0b` and `86067a7` are pushed, the tree is clean,
  and PAC emitted `AMBIENTE: awlz-lab LIBERADO`. The only current PAC operator decision is
  whether to authorize a quota request for 1000 or choose a different AWS-supported path;
  never remove the concurrency cap to work around it.
- **AwLZ:** no owner is live yet. `awlz-lab` is released, so prompt 16 may start now.
- **Kate:** owner is active on `codex/release-d1-d3`. Recovery snapshot/revert and the live
  Falco false-positive correction are proved; the deterministic demo driver is in progress.
  Its uncommitted demo files belong to that owner. Treat VM `kate` as leased until its
  explicit final marker.
- **ProvenancePipeline:** baseline is already finished and public. Prompt 18 waits for
  `AMBIENTE: kate LIBERADA` before any VM revalidation; local/CI audit can run earlier.

## The rules that protect the project

These are the whole reason this portfolio reads as credible rather than as a tutorial. They
outrank convenience, a green build, and finishing on time.

- **Never weaken a control to make something pass.** No `Audit` in place of `Enforce`, no
  `continue-on-error`, no `soft_fail`, no raised threshold, no relaxed default-deny, no
  suppression without a written reason. A gate switched off to make a run green is worse than
  no gate, because it also lies.
- **Never fabricate evidence.** Real command output, pasted verbatim. A negative result
  written down beats a positive one invented. One fabricated number discredits every real one
  in all four repos.
- **An empty `docs/evidence/` is a valid state.** PontoAntiCrack's is empty because nothing
  has been proven there. Report it as "nothing proven yet"; never imply otherwise.
- **Verify before claiming.** Run the command. Do not assert a state you have not observed.
- **Never introduce a static credential.** Local AWS auth is IAM Identity Center SSO; CI is
  GitHub OIDC. This is a stated selling point of the work.
- **Do not mark a roadmap item done without a command that proves it.**

## Keeping the handbook honest

`README.md` carries a status table. **It goes stale the moment a session runs in any
sibling.** Regenerate rather than retype:

```powershell
.\scripts\status.ps1              # console view, with a "needs attention" list
.\scripts\status.ps1 -Markdown    # table ready to paste
```

Every figure in `README.md` was produced that way and should stay that way. The same applies
to claims: if the handbook says a control is proven, there is an artefact in that repo's
`docs/evidence/` behind it.

## Prompts

`prompts/` holds the prompts used to run autonomous sessions, numbered in order. They are
archived because they encode guardrails that took real work to get right, not because the
wording is precious. `prompts/README.md` has the skeleton every new one should follow:

1. **Find the work before starting it** — roadmap, `git log`, progress file.
2. **A resumption contract** — a progress file updated and committed per step, small commits,
   never stopping with a dirty tree. A session can run out of context mid-task.
3. **Explicit authority and its limits.** Standing prohibitions outlive the session that
   wrote them: an earlier prompt banned touching any server, and a later one had to *revoke*
   that for one named VM or the agent would have refused and stalled on step one.
4. **The prohibitions above.**
5. **Stop conditions** — the short list worth interrupting a human for.

`prompts/block-demo-recording.md` is a fragment, not a prompt: paste it into whichever prompt
is about to record a demo.

## Environment

Windows 11 workstation, PowerShell 7. One Debian VM (`ssh kate`) hosts the cluster.

- **Nothing is on `PATH` in a fresh shell.** Tools live under
  `%LOCALAPPDATA%\Microsoft\WinGet\Packages\<Vendor>.<Tool>_*\` and
  `%LOCALAPPDATA%\Python\pythoncore-3.14-64\Scripts`. `python -m <tool>` always works.
  `vmrun` is at `C:\Program Files\VMware\VMware Workstation\`.
- **PowerShell `&&` short-circuits** — a chained check stops at the first failure and the
  rest silently never run.
- `terraform -chdir=$var` does not expand the variable in PowerShell. Use `Set-Location`.
- **In a non-interactive SSH shell `/usr/sbin` is not on `PATH`** — `kubeadm` and `swapon`
  report `command not found` while existing.
- Makefiles assume a POSIX shell — Git Bash or WSL.
- Commits: Conventional Commits, author `heavensnipe@gmail.com`.

## Working style the user expects

- Terse. No preamble, no restating the question. Fragments are fine.
- Security warnings and multi-step procedures get written out clearly, not compressed.
- When a recommendation turns out wrong, correct it in one line and move on.
- Say what is half-done, and exactly where it stopped.
