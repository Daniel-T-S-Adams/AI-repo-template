# Intake

> Canonical procedure for the first agent entering a repository created from
> `AI-repo-template`. It turns a repository full of *machinery with unfilled
> slots* into one configured for a specific project.

This is an **additive** procedure. You are filling in answers, not auditing
inherited files to decide which were speculative. The template ships only two
kinds of thing: machinery that is the same in every project, and slots for the
short list that varies. A small set of contents is genuinely optional, and
[§4](#4-optional-contents) enumerates it so you never have to guess.

Read [workflow.md](workflow.md) once before starting. It explains why each
document exists; this file is the procedure.

## When this applies

Run the intake when **any `«slot:»` marker remains** in `CLAUDE.md`.

Do **not** run it when:

- the repository is `Daniel-T-S-Adams/AI-repo-template` itself — see
  [template/MAINTAINING.md](template/MAINTAINING.md);
- the slots are filled and real project work exists. The intake is a one-time
  event. A newer upstream template baseline is **never** a reason to rerun it —
  that is a baseline-aware reconciliation, and it follows
  [template/TEMPLATE-UPGRADE.md](template/TEMPLATE-UPGRADE.md).

Do not delete existing work. If the repository already contains project
material — source, docs, issues, a README written by a human — that material is
an input to phase 1, not scaffolding to clear away.

## 1. Establish the project

The intake needs a project to be about. In order of preference, take it from:

1. **The current session.** If the human has already described what they are
   building, that is the input. Do not make them repeat it.
2. **`docs/initial_plan.md`**, if present — see phase 1 in
   [workflow.md](workflow.md).
3. **The repository.** Existing code, README, issues, GitHub metadata.

If none of these exist, stop and ask. A template cannot infer a project, and
guessing produces a repository shaped around a system nobody is building.

**Never choose a stack, architecture, deployment target, dependency ecosystem,
or licence without project evidence.**

## 2. Phase 1 — file the plan into its homes

Only if the project is at the planning stage. Skip to [§3](#3-phase-2--fill-the-slots)
if the design is already settled and documented.

**1a.** The human writes `docs/initial_plan.md` in their own words, marking what
they are unsure of and leaving genuinely open questions blank. This is theirs to
write. An agent may sharpen, challenge and extend it — not seed it.

**1b.** Spike every external dependency before treating the plan as settled. A
plan written against a third party's API documentation is fiction until it has
been run against the real thing.

**1c.** Go through `initial_plan.md` statement by statement and file each one:

| Statement is… | Home |
|---|---|
| how the system behaves | a file in `docs/spec/` |
| a decision, and what it ruled out | an ADR in `docs/adr/` |
| something that must be true before proceeding | `docs/checklist.md` |
| work still to be built | a numbered criterion in the first slice's plan |

`docs/spec/` and `docs/plans/` ship empty. `docs/checklist.md` does not exist
yet — create it from the layout in [workflow.md](workflow.md) § "What must be
true before we may proceed".

Then add what `initial_plan.md` does not contain: the slice list and build order
in the checklist, and the schemas, fixtures and a fake for each external service.

**1d.** Delete `docs/initial_plan.md`. Its content has moved. A superseded
planning document left in the repository is exactly the second home for a rule
that this workflow exists to prevent.

Only the **first** slice's plan is written here. Later slices are specified when
they come up.

## 3. Phase 2 — fill the slots

Ten decisions. Each has a home; a decision with no home is one you will make
again in three months.

| # | Decision | Where the answer goes |
|---|---|---|
| 1 | Which document owns what | Context routing table in `CLAUDE.md` |
| 2 | The domain's invariants | `.github/review/invariants.md`, and the domain `must_fix` slot in `CLAUDE.md` |
| 3 | What blocks a merge | Severity definitions in `CLAUDE.md` (already written — extend, don't replace) |
| 4 | The reviewers | The `REVIEWERS` slot in `.github/workflows/ai-review.yml`, and the prompt files in `.github/review/`. Arm with the repository variable `AI_REVIEW_ENABLED=true` and the secret `CLAUDE_CODE_OAUTH_TOKEN` (`claude setup-token`) or `ANTHROPIC_API_KEY` |
| 5 | The check command | The `*_CMD` slots in `Makefile`. Unconfigured targets fail rather than no-op, so CI stays red until this slot is filled — that is the intended signal, not a bug |
| 6 | Deterministic feedback | `fixtures/`, and a fake for each external service |
| 7 | What only a human may do | Human-only actions in `CLAUDE.md` |
| 8 | What must be green, and how a PR lands | **Branch protection on GitHub — not in the repository.** Record the intended state via `scripts/secure-repo.sh` and its config, so a silently removed required check is detectable |
| 9 | The unit of work | Issue template, and the criteria ID scheme |
| 10 | Who reads what landed, and how often | An ADR recording the answer. "Nobody" is valid — this template does not ship a mechanism for it (see ADR 009). Under manual merge, slot 8 usually answers it |

**Slots 5 and 6 depend on a phase-1 decision the table does not list:** where
the thing runs, and the stack that follows. A check command and a fixture shape
cannot be chosen without it, and §1 forbids inventing it. If that decision has
not been made, those slots stay open, CI stays red, and the intake is
**incomplete on purpose** — record the blocking question in the intake ADR and
stop. A repository honestly blocked on a human decision is a better outcome
than one shaped around a guess.

Do not try to decide everything. Capability that depends on evidence you do not
have yet — extra specialist reviewers, deployment gates — belongs in a plan with
an explicit trigger, not in this pass.

### Slot 8 in particular: how a PR lands

Three settings, and the middle one is usually right for a solo project:

- **Automatic.** Checks and reviewers decide; a green PR merges itself. Set the
  repository variable `AUTO_MERGE_ENABLED=true`, and
  `required_approving_review_count` to `0`. `auto-merge.yml` refuses to arm
  unless `allow_auto_merge` is on *and* a required-status-check rule exists, so
  it cannot merge into a repository where nothing has to be green.
- **Manual merge.** A green PR waits for the human to press Merge. Leave
  `AUTO_MERGE_ENABLED` unset; keep approvals at `0`. Branch protection still
  blocks the merge until checks pass. This is the default.
- **Approval required.** Only workable with more than one person. A solo
  repository cannot approve its own PRs, so every merge becomes an
  administrative override — which trains you to bypass your own protections and
  is worse than not having them.

For a one-off change that needs a human, open that PR as a **draft**: drafts are
not auto-merged and their reviewers do not run, so marking it ready is itself
the approval. No settings change.

## 4. Optional contents

Everything not listed here is machinery — keep it. These are genuinely
project-dependent. Decide each, and record removals in the intake ADR.

| Contents | Keep when |
|---|---|
| `welcome`, `stale`, `lock-threads`, `auto-label`, `pr-size`, `sync-status`, `scan-pr-body` workflows | The project takes outside contributions. A solo agent-driven repository does not need them. |
| `publish-package.yml` | You publish a package to a registry. |
| `release.yml` | You cut versioned releases. |
| `.github/ISSUE_TEMPLATE/`, `scripts/labels.sh` | You use GitHub Issues as the unit of work (slot 9). |
| `.devcontainer/` | Contributors need a reproducible environment. |
| `docs/GITHUB-ENVIRONMENTS.md`, `docs/FORK-SECURITY.md` | You deploy to environments, or accept fork PRs. |
| `docs/PROD_CHECKLIST.md` | Keep as a generic reference. It is **not** `docs/checklist.md`, which is this project's own gate file. |
| `.claude/skills/` general utilities | Per skill. They are conveniences, not workflow machinery. |
| `docs/template/` | Keep. It holds the template's own decisions, maintenance contract and upgrade SOP — **not** this project's. It is deliberately outside `docs/adr/` so it never occupies your ADR numbering; your first record is `001`. |

**Never optional:** the security substrate (secret scanning, CodeQL, dependency
review, SHA-pinned actions and the Dependabot config that maintains the pins,
the pre-commit hooks, `.gitignore`, `.gitattributes`), `scripts/secure-repo.sh`,
`LICENSE`, `SECURITY.md`, and the review pipeline. The more of the merge
decision you automate, the more these carry — under automatic merge they are
the only thing between an agent-authored PR and the default branch.

## 5. Settings GitHub does not carry over

Creating a repository from a template copies files. It does not copy repository
settings, and nothing in the repository will tell you they are missing.

- Install the local hooks: `bash templates/hooks/setup-hooks.sh`
- Apply protection, the merge mode, and the security settings:

  ```bash
  bash scripts/secure-repo.sh --merge-mode manual   # or: --merge-mode auto
  ```

  `--merge-mode` sets the repository setting and the workflow's arming
  variable together. Setting one without the other produces PRs that sit green
  and never merge, with nothing anywhere explaining why; the audit below
  reports that state as a hard failure rather than a warning.

- Arm AI review, once you have filled slot 4's prompts:

  ```bash
  gh secret set CLAUDE_CODE_OAUTH_TOKEN   # from `claude setup-token`
  gh variable set AI_REVIEW_ENABLED --body true
  ```

  Until this is done the verdict gate passes with a warning saying plainly
  that nothing was reviewed. That is deliberate — it lets the gate be a
  required check from day one — but it is not review.

- Verify everything landed: `bash scripts/secure-repo.sh --audit`
- Create labels, if using the issue taxonomy: `bash scripts/labels.sh`
- Confirm `CODEOWNERS` names an account that actually has access to *this*
  repository.

Two of these are settings a GitHub template genuinely cannot carry: the
dependency graph (without it `dependency-review.yml` cannot run) and
Dependabot security updates. `secure-repo.sh` enables both.

## 6. Completion

The intake is done when:

- no slot marker remains in any **configuration** surface:

  ```
  git grep -n '«slot:' -- CLAUDE.md AGENTS.md Makefile \
      .github/review/ .github/workflows/ai-review.yml .github/workflows/ci.yml
  ```

  These are the files that carry real slots. `README.md`, this file and ADR 008
  mention the marker in prose and always will, so a repo-wide grep is not the
  check. `CLAUDE.md` is not the only surface that matters: an unfilled
  invariants prompt leaves that reviewer checking nothing while still voting
  `approve`;
- `docs/spec/` has at least one owning file and the routing table lists it;
- `docs/checklist.md` exists with the slice list and build order;
- the first slice's plan exists with numbered criteria;
- the check command runs and fails honestly when something is broken — prove
  it by breaking something, not by reading the Makefile;
- the review gate ran on a real PR and its verdicts are bound to the head
  commit;
- an ADR records the intake decisions, including anything removed under §4;
- the Repository state section of `CLAUDE.md` and `AGENTS.md` is deleted,
  exactly as those files' Derived-repository mode paragraph specifies. Follow
  that instruction; do not restate it from memory. Every other section stays.

Record the decisions as an ADR rather than in this file. This file is the
procedure and stays generic; what *this* project decided is a durable choice
someone will later ask about.

---

> See also: [workflow.md](workflow.md) | [template/TEMPLATE-UPGRADE.md](template/TEMPLATE-UPGRADE.md) | [../CLAUDE.md](../CLAUDE.md)
