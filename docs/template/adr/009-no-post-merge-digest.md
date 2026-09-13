# ADR 009 — No Post-Merge Digest

> The template does not ship a mechanism for looking at the default branch after changes land. Nobody reads merges, by decision.

**Status:** Accepted
**Date:** 2026-09-10

## Context

Under this template's model, AI review is the only pre-merge gate. Where the merge mode is `auto` (ADR 008, `docs/INTAKE.md` slot 8), a change can go from an agent to the default branch with no person involved at any point.

A post-merge digest was proposed to cover three gaps that opens:

1. **Nobody knows what landed.** A summary of what merged since the last one keeps a maintainer's model of the project current.
2. **`should_fix` findings accumulate unresolved.** They do not block, so a PR merges with them outstanding and nothing in the system raises them again.
3. **Escapes are unmeasured.** When a defect reaches the default branch, nothing records whether the reviewers approved the PR that introduced it.

Gap 3 is the substantive one. It is the only available evidence about whether the review layer prevents anything, as distinct from whether it ran — and "did it run" is all the verdict gate can tell you.

## Decision

Do not ship a post-merge digest, an escape-tracking convention, or any other after-the-fact review mechanism. Slot 10's answer for this template is **nobody**.

The digest section is removed from `docs/workflow.md` rather than left as a documented-but-unimplemented practice: a workflow document describing a habit the project does not perform is a rule with no home, and readers cannot tell which parts are real.

Slot 10 itself stays in the intake. The question is genuine and a derived project should answer it deliberately; the template simply does not presume the answer, and does not supply a mechanism.

## Consequences

### Positive

- No scheduled report to generate, and no artifact whose only value depends on someone reliably reading it. A digest nobody reads is worse than none: it creates the appearance of oversight without the substance.
- Under manual merge — the template's default — gap 1 largely does not arise. Whoever presses Merge is the person who looks.
- One fewer moving part, and one fewer slot demanding a real answer before the pipeline is usable.

### Negative

- **Review quality is unmeasured, permanently.** There is no way to tell whether the reviewers catch anything. Every future decision about the review layer — add a reviewer, change a model, rewrite a prompt, widen the invariants — is made without evidence. This is accepted knowingly, not overlooked.
- `should_fix` findings are recorded only in comments on closed pull requests. In practice they are decided once, at the moment the reviewer raises them, or not at all.
- Under `auto` merge, nothing observes the default branch. The consequence is bounded by the verdict gate being fail-closed and by the human-only actions list, both of which remain in force — but neither detects a change that passed review and was wrong anyway.

### Neutral

- The decision is reversible and cheap to reverse. Escape tracking in particular needs no workflow: a label convention on bug issues plus a lookup of the introducing PR's verdicts would supply gap 3 on its own.

---

> See also: [ADR 008](008-slot-based-intake.md) | [Intake](../../INTAKE.md) | [Workflow](../../workflow.md)
