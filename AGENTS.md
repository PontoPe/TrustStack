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

## Two kinds of session

**A repo session** is opened *inside* a sibling and does deep work there — building,
applying, recording. It must not touch the other repos at all.

**An overlooker session** is opened *here* and coordinates across all five directories. It
may write into siblings, because cross-cutting work genuinely exists: a finding one repo
makes about another, a stale cross-reference, a convention adopted in one place and owed to
the rest. That authority carries one condition, and it is not optional:

> **Before writing into a sibling, read that repo's agent instructions and its handoff, and
> obey its conventions, gates and invariant tests.** Run its validation entrypoint before
> committing — `make validate`, `tests/repo_invariants.sh`, `pytest`, `terraform validate`,
> whichever that repo uses. Commit inside that repo, with its author convention. **Never a
> commit that spans two repositories.**

An overlooker does not do a repo's deep work. If a task needs a cluster brought up, a stack
applied, an attack detonated or a demo recorded, it belongs in a repo session — write the
prompt into `prompts/` and hand it over. A good prompt is as real a deliverable as a commit.

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
