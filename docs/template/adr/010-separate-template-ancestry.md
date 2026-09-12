# ADR 010 — Separate template ancestry from a project's own records

> The template's decision records move to `docs/template/adr/`, so a derived repository's ADR numbering starts empty at `001`.

**Status:** Accepted
**Date:** 2026-09-12

## Context

Running the intake end to end against a real generated repository (`pr-digest`) surfaced five defects. Four were local and are fixed in the same change as this record: absent document homes, an unnamed prerequisite for two slots, an ambiguous deletion instruction, and a slot marker above a working default.

The fifth is structural. A derived repository inherited **nine ADRs recording the template's own design** — SHA-pinned actions, rulesets, the intake, and so on — directly into `docs/adr/`. Nothing told the first agent what to do with them. The consequences were concrete: it was unanswerable whether the project's first record should be `001` or `010`, and the generated project happened to be called `pr-digest`, which inherited a record titled *"No Post-Merge Digest"* that had nothing to do with it.

## Decision

Move the template's ADRs to `docs/template/adr/`, beside `MAINTAINING.md` and `TEMPLATE-UPGRADE.md`, which are already scoped as template-owned. `docs/adr/` ships containing only `000-template.md`, the format to copy.

The records are kept rather than withheld: they explain why the inherited machinery is shaped as it is, which is exactly what a template upgrade needs. They simply are not the project's decisions and must not occupy its numbering.

`docs/spec/` and `docs/plans/` now ship as empty directories, because the intake instructed agents to file into homes the template did not create. `docs/checklist.md` is still written during intake — `workflow.md` already carries its layout, and shipping an unfilled gate file would be ceremony.

## Consequences

### Positive

- A derived project's first ADR is unambiguously `001`.
- The template's own reasoning stays available under `docs/template/`, where the upgrade SOP already looks.
- Phase 1 can be followed as written rather than requiring the agent to infer that three of four homes need creating.

### Negative

- Template ADR links moved one level deeper and had to be repointed; a future move will need the same care.
- `docs/template/` grows to hold three kinds of thing (contract, upgrade SOP, decisions). That is still one owner, but the directory is no longer self-evidently one topic.

### Neutral

- Existing derived repositories that already carry the ADRs in `docs/adr/` are unaffected. Relocating them is a reconciliation choice, not a compatibility break, and does not require a baseline bump: no downstream bootstrap or agent-routing behaviour changes.
