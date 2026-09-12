# ADR 008 — Slot-Based Intake Supersedes Phase 0

> Replace the subtractive first-agent normalization step with an additive one: the template ships machinery plus explicit slots, and the first agent fills them rather than classifying what to delete.

**Status:** Accepted
**Date:** 2026-09-10
**Supersedes:** [ADR 006](006-agent-native-phase-zero.md)

## Context

ADR 006 established Phase 0 on a premise that held for a general-purpose repository template: GitHub template creation copies *everything*, including marketing, examples, optional workflows, and placeholder project assumptions, so the first agent's job is to decide what survives. Its central mechanism was a KEEP / ADAPT / REMOVE / DEFER classification pass over inherited artifacts.

The project's objective has since narrowed: this template exists to produce repositories ready for **agent-driven development pipelines** — an AI review gate, a defined merge policy, a single check command, a context architecture with real ownership and precedence.

Against that objective the Phase 0 premise is wrong in a specific way. The development pipeline is the same in every project; only a short list of answers varies — which documents own what, the domain invariants, what blocks a merge, the reviewers, the check command, what only a human may do, how a PR lands. A template built on that observation ships **machinery plus slots**, and there is nothing speculative to remove.

Phase 0 also had two practical costs:

- **Classification is unbounded.** Asking an agent to sort every inherited file into four buckets invites judgement on files whose purpose it cannot evaluate, and produces different answers on different runs.
- **A slot cannot be inferred.** Phase 0 had no representation for "this is a question nobody has answered yet", so unanswered questions were resolved silently rather than surfaced.

## Decision

Replace `docs/PHASE-0.md` with `docs/INTAKE.md`, an additive procedure.

1. **Slots are the detection signal.** `CLAUDE.md` ships with `«slot:»` markers. Any remaining marker means the intake has not run. This replaces "generic instructions are still present" — a heuristic that could not distinguish an unconfigured repository from a configured one that happened to keep template prose.
2. **The template declares what is optional**, in one enumerated table with a "keep when" condition per entry. An agent never classifies inherited files. Everything not in that table is machinery.
3. **A security floor is stated and non-negotiable.** Secret scanning, CodeQL, dependency review, SHA-pinned actions, the pre-commit hooks and `scripts/secure-repo.sh` are never optional — under automatic merge they are the only thing between an agent-authored PR and the default branch.
4. **The reasoning layer moves to `docs/workflow.md`**, which owns the document taxonomy (`spec` / `adr` / `plans` / `checklist`), edit triggers, lifecycle, and escalation rules. `CLAUDE.md` stays terse and carries only rules that must be obeyed every time.
5. **`CLAUDE.md` and `AGENTS.md` become byte-identical**, with a tool-neutral title, and CI enforces it. Behavioural drift between the two agent surfaces stops being possible by construction rather than by discipline.

## Consequences

### Positive

- An unanswered question is now visible in the repository as an unfilled slot, rather than being silently resolved. Escalation has a mechanism instead of relying on an agent's restraint.
- Intake outcomes are repeatable: the optional set is fixed and enumerated, not re-derived per run.
- The template stops shipping content whose purpose is to be deleted, so the derived repository is smaller and its remaining contents are all load-bearing.
- Agent instructions cannot drift between Claude Code and Codex.

### Negative

- The template is more opinionated about how a project is developed. A project that does not want AI review, a single check command, or the four-document taxonomy inherits structure it must undo — the opposite of Phase 0's failure mode, and a real cost.
- The optional table in `INTAKE.md` is a maintenance surface: adding template content means deciding whether it is machinery or optional, and recording that.
- Downstream repositories created under Phase 0 refer to a procedure that no longer exists. They are covered by [TEMPLATE-UPGRADE.md](../TEMPLATE-UPGRADE.md), which reconciles semantically and never reruns intake for a mature project.

### Neutral

- ADR 006 remains accurate as a record of why Phase 0 existed. It is superseded, not withdrawn.

---

> See also: [ADR 006](006-agent-native-phase-zero.md) | [Intake](../../INTAKE.md) | [Workflow](../../workflow.md)
