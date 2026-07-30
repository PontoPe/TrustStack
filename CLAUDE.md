# TrustStack — context for Claude Code

This directory manages a four-repository portfolio. It contains **no infrastructure code of
its own** and never will.

## What lives here

| Path | What it is |
|---|---|
| `README.md` | The portfolio handbook — thesis, status, how the repos interlock, findings, cost, what is next |
| `prompts/` | The session prompts that built each repo, archived and reusable |
| `scripts/status.ps1` | Reads the four repos and reports their real state |

The four repositories are **siblings**, not children: `../AwLZ`, `../ProvenancePipeline`,
`../KateClusters`, `../PontoAntiCrack`. Each is its own git repository with its own
`CLAUDE.md`, handoff, ADRs, and threat model.

## The rule that matters here

**Never write into a sibling repository from this directory.** Reading them is the whole
point; writing to them from here bypasses their own conventions, CI gates and invariant
tests. If something needs to change in `KateClusters`, it changes in a session opened in
`KateClusters`.

The one exception is `README.md` describing what those repos contain — that is reporting,
not writing.

## Keeping the handbook honest

`README.md` carries a status table and per-repo state. **Both go stale the moment a session
runs in any sibling.** Before trusting or updating it:

```powershell
.\scripts\status.ps1              # console view, with a "needs attention" list
.\scripts\status.ps1 -Markdown    # table ready to paste
```

Read the repos; do not carry numbers forward from a previous version of the document. Every
figure in `README.md` was produced that way and should stay that way.

The same applies to claims. If the handbook says a control is proven, there is an artefact in
that repo's `docs/evidence/` behind it. An empty evidence directory is a valid, reportable
state — say "nothing proven yet", never quietly imply otherwise.

## Prompts

`prompts/` holds the actual prompts used to run autonomous sessions, numbered in the order
they were used. They are archived because they encode guardrails that took real work to get
right, not because the wording is precious.

Every one of them shares the same skeleton, and a new prompt should too:

1. **Where the work stands** — read `CLAUDE.md`, the handoff, `git log`, and any
   `docs/PROGRESS.md`, before assuming a clean start.
2. **A resumption contract** — a progress file updated and committed per step, small commits,
   never stopping with a dirty tree. A session can run out of context mid-task; the next one
   must be able to continue without guessing.
3. **Explicit authority and its limits** — what the agent may touch, and what is off-limits.
   Earlier prompts forbade touching any server; a later one had to revoke that for one
   specific VM. Without an explicit revocation the agent refuses and stalls.
4. **The prohibitions that protect the thesis** — never weaken a control to make something
   pass, never fabricate evidence, never write to a sibling repo.
5. **Stop conditions** — the short list of things worth interrupting a human for.

`prompts/block-demo-recording.md` is a fragment, not a whole prompt: paste it into whichever
prompt is about to record a demo.

## Working style the user expects

- Terse. No preamble, no restating the question. Fragments are fine.
- Security warnings and multi-step procedures get written out clearly, not compressed.
- Verify before claiming. Run the command; do not assert the state.
- When a recommendation turns out wrong, correct it in one line and move on.
