# How this project is developed

Orientation for a human, and for an agent that wants the reasoning behind a
rule. The rules themselves are in `CLAUDE.md`, which is deliberately terse.
Nothing here overrides it.

Read this once, at the start.

## The three phases

**Phase 1 — plan.** Decide what you are building and write it down as
documents an agent can act on. This is where almost all human judgement is
spent, and the phase most people rush.

**Phase 2 — fill the workflow slots.** The development workflow is fixed
across projects; what varies is a short list of project-specific choices —
what the domain invariants are, what the check command runs, what only a
human may do. Phase 2 works that list.

**Phase 3 — implement.** An agent takes the next acceptance criterion, works
on a branch, opens a PR, and the review gate decides whether it lands. Your
input here is *reactive*: the agent escalates, you answer.

The phases are not one-way. Implementation regularly discovers that the plan
was wrong, and amending phase 1's documents is part of the work rather than
an interruption to it.

## What the documents are for

Read this once before writing any of them.

On a human team, documentation is a convenience. Here it is the thing agents
act on, which changes what a mistake costs. A human who finds two conflicting
rules in a wiki asks someone. An agent picks one, implements it, and the PR
looks perfectly reasonable. So the docs need a shape, and it turns out there
are only four things a document is ever doing.

```
docs/
├── spec/            what is true now — one file per area
├── adr/             why it is that way — numbered, never edited
├── plans/           what we are doing next — numbered criteria
└── checklist.md     what must be true before we may proceed
```

### 1. What is true now — the spec

The rules of your system, as they stand today. *"A refund can only be issued
against a settled payment."* *"An account is locked after five failed
sign-ins."*

They live in `docs/spec/`, one file per area — `docs/spec/refunds.md`,
`docs/spec/accounts.md`. Which files exist is itself a planning decision:
split by area of meaning, and test the split by asking whether two files
could each plausibly own the same rule. If they could, the split is wrong.

**Written** in phase 1, before any code. In an AI-first project these are
most of what planning produces, because they are what an agent reads before
it writes anything.

**Edited** on exactly two triggers:

1. **A change to meaning — in the same PR that makes the change.** Never a
   follow-up "update the docs" PR: that gap is precisely where code and spec
   drift apart, and the whole value of the spec is that it never lags.
2. **When you discover the document is wrong.** Once code exists the spec is
   *intent*, not truth. If an agent finds the implementation disagreeing with
   it, that is a finding to resolve, not a discrepancy to ignore.

Nothing else is a reason to edit a spec file. In particular, never copy a
rule in from another document because it would be convenient to have it in
both places — link instead.

### 2. Why it is that way — decision records

An **ADR** (Architecture Decision Record) is a short note about one choice:
what you were deciding, what you picked, and what it cost you.

> *We chose PostgreSQL for the ledger. We considered a message queue and
> rejected it because we would have lost transactional writes across the
> ledger and the job table. The cost is that we are limited to one region.*

The spec tells you the system uses PostgreSQL. Only the ADR tells you that
this was a *decision* rather than an accident, and what breaks if someone
undoes it. Without it, a future agent — or you in six months — "simplifies"
the design by throwing away a trade-off that was made deliberately.

That is also why an ADR is **never edited**. If you later move off
PostgreSQL, you do not update the old note; you write a new one that says so
and supersedes it. The folder is a diary of reasoning in the order it
happened, not a description of the current system — which is why it reads
strangely if you go there looking for documentation.

Write one whenever a choice is durable enough that someone will later ask
"why is it like this?" — including decisions about *how the project is run*,
not only about its architecture. A governance decision recorded in a plan
disappears when that plan is archived.

That trigger is a moment, not a phase. In practice a project writes a cluster
at the very start — language, datastore, process boundaries, the choices that
are hard to reverse — and then a steady trickle for as long as it is being
built, because building is what surfaces decisions nobody knew were coming.
The trickle matters more than the cluster: those are the choices made with
the least ceremony and the ones most likely to be quietly undone later.

### 3. What we are doing next — plans

One plan per slice (see "Slices" below), holding that slice's acceptance
criteria: numbered statements of what will be true when it is done.

> *D1. A refund cannot exceed the settled amount of its payment.*
> *D1a. A refund against a partially-refunded payment is bounded by the
> remaining balance.*
> *D2. Refund attempts are idempotent on `(payment_id, idempotency_key)`.*

The numbering is the part that matters. Once criteria have IDs, "do D2 next"
is a complete instruction, a PR title can cite `(D2)`, and a commit landing
months later still traces back to the decision that caused it. A plan without
IDs is just prose, and you will re-explain it every session.

**A slice is not a plan.** The slice is the unit of work; the plan is the
document that specifies one. The list and order of slices lives in the
checklist; each slice's plan is its own file in `docs/plans/`.

**Written** just before its slice starts — never all up front. Criteria for a
slice you have not reached are hypotheses about a system that does not exist
yet, and they will be wrong in ways you cannot currently detect.

**Structured** as frontmatter (`title`, `status`, `created`, source issue),
then criteria grouped by area: a letter for the group, a number within it.
Two properties make this work:

- **Criteria are statements about the finished system, not tasks.** *"A
  refund cannot exceed…"*, never *"implement refund validation"*. A statement
  can be checked by a reviewer; a task can only be ticked off by whoever did
  it.
- **IDs are append-only and never reused.** `D1a` exists because inserting a
  criterion between `D1` and `D2` would renumber everything after it, and PR
  titles cite these permanently. Suffix to insert; never renumber.

**Edited** on the same two triggers as the spec — the document turns out to
be wrong, or something about the work changes — plus one the spec does not
have: criteria are marked as they land.

Two things genuinely differ, and neither is the frequency:

- **Coupling.** A spec change must ride in the same PR as the change that
  caused it. A plan amendment may be its own PR, before or after the work.
  A stale spec is read as current truth and makes an agent do the wrong thing
  *today*; a stale plan is only wrong about what comes *next*.
- **The kind of judgement.** Correcting a spec is mechanical — the code is
  the answer, so the document is brought to match it. Correcting a plan is a
  decision, because there is nothing to check it against: the thing it
  describes does not exist yet. That makes plan amendments a place where an
  agent should escalate rather than quietly rewrite.

Amendments are dated notes rather than silent rewrites, so it stays visible
that `D2` changed after the work that exposed the problem.

**Frozen when its slice completes.** Set `status: complete` and stop editing
it: the plan becomes history, like an ADR, because commits cite `D2` forever
and rewriting it breaks that trail. This is the opposite of the
`initial_plan.md` rule below, and the difference is the point —
`initial_plan.md` is deleted because its content *moved* into the spec, while
a completed plan is kept because its criteria were *executed and cited*.

`status` is one of `draft`, `active`, `complete`, `superseded`.

**A frozen plan does not go stale**, which surprises people. It is not a
claim about the present — it says *what this slice set out to do, and did* —
so a later slice changing that behaviour leaves it untouched and true. The
change goes into `docs/spec/`, which is where current truth lives. If a later
slice invalidates the whole approach, mark the old plan `superseded` with a
pointer to its replacement; still do not edit its contents.

A useful diagnostic: **if you want to edit a completed plan's criteria, you
have found a rule with two homes.** The behaviour was living in the plan when
it belonged in the spec. Move it there; leave the plan alone.

On completion, give a plan a one-line header saying so — *"Records slice 1
as built; current behaviour is in `docs/spec/`."* Precedence already ranks
plans below the spec and the code, but a reader opening the file deserves to
be told before they trust `D2` as a description of today.

### 4. What must be true before we may proceed — the checklist

Every project reaches a version of this moment. The launch is on Friday,
everything works, and someone asks whether anyone has actually tried
restoring from a backup. Nobody has. Caring about it is now expensive, so the
honest answer quietly becomes "we'll do that next week".

`docs/checklist.md` is where you answer that question months early, while
saying "not yet" is free. It is the one file in the project that is allowed
to stop you.

> - [ ] A restore from backup has been tested end to end.
> - [ ] A threat model covering account takeover exists.
> - [x] Secrets load from an untracked source; none are in the repository.
>       — policy in `CLAUDE.md`; `secrets/` ignored; scanner in `make check`

**How it differs from a plan.** Both are numbered lists of things that are
not done yet, so on the page they look identical. The difference is what
happens if an item is never done:

- *"Refund attempts are idempotent."* Someone writes code. If it never
  happens, a feature is missing and everyone works around it.
- *"A restore from backup has been tested."* Someone runs a drill. If it
  never happens, **you are not allowed to launch**.

A plan criterion is a target. A checklist item is a stop sign. That is also
why there is one checklist and many plans: features are built one slice at a
time, but you only cross "handles real money" once.

**Write it in phase 1**, with the spec, and add to it whenever a new kind of
risk shows up for the first time — real money, a deployed environment, an
outside user, production credentials. Writing a gate at the moment you want
to cross it does not work; by then it is a negotiation rather than a gate.

**How it is laid out.** The items sit in topic sections. A short list at the
top, the milestones, says which sections you need for each step — *"ready to
deploy: sections 1 to 3"*.

It works that way round because one item often guards several milestones.
"No secrets in the repository" matters before you deploy *and* before you
take real money. Written under both headings it becomes two copies, and two
copies are how an item ends up ticked in one place and forgotten in the
other.

```markdown
# <project>: checklist

Status: active
Last updated: 2026-03-14

<One paragraph: what this file gates, and what it exists to stop from
happening.>

## How to use this checklist

- Leave an item unchecked until its stated output exists and has been
  reviewed.
- Link the resulting document, test, decision record or report beside the
  completed item.
- Never un-tick, weaken or delete a gate in order to unblock yourself.

## Milestones

- **Ready for first deployment:** sections 1–3 complete.
- **Ready to handle real money:** sections 1–5, and section 6 in full.

## 1. Secrets and configuration

- [x] Secrets load from an untracked source; none are in the repository.
      — policy in `CLAUDE.md`; `secrets/` ignored; scanner in `make check`
- [ ] A restore from backup has been tested end to end.

## 2. Build order

- [ ] Slice 1 — <name>. Ends with <what observably runs>.
- [ ] Slice 2 — <name>.

## 6. Gates before real money

- [ ] A threat model covering account takeover and abuse exists.
      Declared met by: <named human>.

## Final readiness checks

- [ ] Every section above is complete, or its incompleteness is recorded
      with a reason.
```

Four habits keep it honest, and without them the file becomes decoration
within a month.

**Never tick without saying why.** Anyone can type an `x`. The line
underneath — naming the document, the test, the commit that makes it true —
is the difference between a record and a wish. If something is half done,
write *"Outstanding: …"* beside it. That is more useful than ticking it, and
much more useful than silence.

**Write items you could be proved wrong about.** *"A threat model exists"* is
checkable. *"Security is good"* is not, and will be ticked at 6pm on a Friday
by someone who badly wants to go home.

**Say who decides**, when meeting a gate is a judgement rather than an
observation. "Tested end to end" is visible to anyone. "The threat model is
adequate" needs a named person, or it will be settled by whoever is keenest
to proceed.

**Never un-tick or soften a gate to get yourself unblocked.** A gate the
blocked party can remove is not a gate. If one is genuinely wrong, changing
it is a human decision — it sits on the human-only list in `CLAUDE.md`
alongside weakening a test or a review gate.

Otherwise you edit this file constantly: ticking items as they are met,
adding gates as new risks appear, correcting a bar that turns out to be in
the wrong place.

This file also carries the **slice list and build order** — which slice comes
next is a sequencing question, and "slice 4 may not start before slice 3" is
the same kind of statement as everything else here.

### Two rules that hold it together

**One rule, one home.** Never copy a rule into a second document "for
convenience". The copies drift within weeks, and then nobody — human or agent
— can tell which is current. If you want to duplicate, link instead. The
routing table in `CLAUDE.md` is how you find the right home.

**A disagreement is a finding, not a formality.** When two documents, or a
document and the code, say different things, that is a defect someone has to
resolve — it is never something to tidy away in passing.

Precedence tells you which one to *trust in the meantime*: code and tests
over the spec, the spec over the plans. ADRs sit outside the contest; they
are history, so they are never wrong, only superseded.

Precedence does **not** tell you which one to change, and the difference
matters. If the code contradicts the spec, either the spec is stale or the
code has a bug, and nothing about the ordering distinguishes those. Editing
the spec to match the code is how a real bug becomes documented behaviour.
So: trust the code while you work, and escalate the conflict rather than
silently resolving it.

That is also an argument for writing fewer rules down and enforcing more of
them. A sentence in the spec can quietly stop being true and nothing happens;
the same rule as a test, a schema or a scanner fails the moment it stops
being true. Whenever a rule can be made to enforce itself, that is worth more
than stating it well.

## Phase 1 — plan

**1a.** A human writes `docs/initial_plan.md`: as much of the design as they
can, in their own words. **Mark the parts you are unsure of, and leave
genuinely open questions blank.** This is the highest-value act in the whole
workflow — see "Front-load the questions" below.

**1b.** Discuss it with an agent to sharpen, challenge and extend it. The
human seeds the design; the agent refines it. Not the reverse.

**1c.** Spike every external dependency before treating the plan as settled.
A plan written against a third party's API documentation is fiction until it
has been run against the real thing. Findings amend the plan.

**1d.** Go through `initial_plan.md` statement by statement, and file each one
where it belongs:

- how the system behaves → a file in `docs/spec/`
- a decision the plan records, and what it ruled out → an ADR
- something that must be true before you may proceed → the checklist
- work still to be built → a numbered criterion in the first slice's plan

Then add the things `initial_plan.md` does not contain: the slice list and
build order, in the checklist; and the schemas, fixtures, and a fake for each
external service.

Two things this step is *not*. It is not where most ADRs come from — it is a
salvage pass, because `initial_plan.md` is deleted at the end of it and any
reasoning still sitting in the file dies with it. Decisions made after this
point get their ADR when they are made, which for most of a project's life
means phase 3.

And it is not where every slice is specified. Only the **first** slice's plan
is written here; the rest are written when their slice comes up.

`initial_plan.md` has served its purpose once 1d is complete. Delete it — a
superseded planning document that stays in the repository is exactly the
second home for a rule that this workflow exists to prevent.

### Slices — the unit of work

A **vertical slice** is a piece of work cutting through every layer — schema,
service, tests, observability, docs — that ends in something which actually
runs. The opposite is building horizontally: the whole schema, then the whole
API, then the workers, with nothing testable until the end.

Slices matter here for a reason beyond the usual ones: **they are what keeps
the feedback loop alive.** Horizontal layers give an agent no signal for
weeks, because nothing can be executed. A slice ends in something runnable,
so the plan's guesses are corrected early and a wrong plan costs one slice
instead of the project.

- **The slice list and its order live in one place** — the checklist, not the
  plans. A plan specifies one slice; it never decides which comes next.
- **Slicing is a human decision.** It is a scope call — what is in, what is
  out, in what order — and it is the highest-leverage judgement in the
  project, because bad boundaries make everything downstream wrong. An agent
  may propose a decomposition; the human owns it.
- **Order slices to retire the largest uncertainty first**, not to build
  foundations first. "Foundations first" is horizontal thinking wearing a
  different hat. Whatever is most likely to invalidate the plan goes first,
  preceded by a spike if it is external.
- **A slice must end in something demonstrable.** If you cannot say what
  observably works when it lands, it is a layer, not a slice.
- **Right-sized when its plan can be written in one sitting.** Longer, and
  the slice is too big for its criteria to stay accurate; much shorter, and
  it probably is not demonstrable.
- **One slice active at a time.** Several agents may work in parallel on
  different criteria within it — that is what the numbered IDs are for — but
  parallel *slices* reintroduce exactly the integration risk that slicing
  exists to avoid.
- **Re-slice after each slice lands.** The remaining list is hypotheses in
  the same way criteria are. Before starting the next one, ask whether it is
  still the right next one.

## Phase 2 — fill the workflow slots

### What you are configuring

Nothing above has explained how a change actually gets accepted, and phase 2
is entirely about that, so here it is.

Every PR has two things run against it. A **check command**: one command that
builds, lints and tests, with no failure masked. And one or more **AI
reviewers**: each is a model plus a prompt giving it a lens, which reads the
diff and returns a verdict — approve, or changes needed with findings, each
finding carrying a severity.

Taking those terms in turn:

- **build** — turn the source into a running program. Catches anything that
  is not valid code.
- **lint** — static analysis for code that builds correctly but is wrong or
  risky anyway: an ignored return value, an unsafe conversion, a pattern the
  project has banned.
- **test** — run the automated tests.
- **no failure masked** — if any step fails, the whole command fails. The
  obvious way to break this is appending something like `|| true` to a step
  so it always reports success. The quiet way is a test that skips itself
  when a dependency is missing: the command stays green while the coverage
  silently disappears.

Those verdicts are machine-readable and tied to the exact commit, so a **gate**
can add them up mechanically: any reviewer withholding approval, erroring, or
reporting on a stale commit, and the PR does not merge. **Branch protection**
is what makes that binding rather than advisory — it is a setting on the code
host naming which checks must be green before the default branch will accept
anything.

A red gate is not the end of the process, it is the loop. The author fixes
what was found and pushes; **every push triggers a completely fresh review of
the new commit**, with superseded runs cancelled. Because a verdict is bound
to a commit, an approval never carries over to code that has changed since —
which is what stops "approved once, then edited" from reaching the default
branch. What an agent may and may not do inside that loop is in phase 3.

That machinery is the same in every project. What differs is what goes in it.

### The list

Ten decisions. For each, what you are deciding and where the answer is kept —
a decision with no home is one you will make again in three months.

1. **Which document owns what.** The files in `docs/spec/` and what each
   covers. *→ the routing table in `CLAUDE.md`.*
2. **The domain's invariants.** The handful of things that must never quietly
   become false — money is conserved, one record has one owner. *→ the
   invariants reviewer's prompt file, and the domain-specific `must_fix`
   examples in `CLAUDE.md`.*
3. **What blocks a merge.** The definitions of `must_fix`, `should_fix` and
   `nit`. Do not skip this: leave severity undefined and the models decide
   what blocks, and two good models will label the same finding differently.
   *→ `CLAUDE.md`.*
4. **The reviewers.** How many, which models, and the lens each is given.
   Start with two: general correctness, and domain invariants. *→ the CI
   workflow file, and the prompt files it points at.*
5. **The check command.** What one command runs — toolchain, linters, tests,
   scanners. *→ a Makefile or equivalent, named in `CLAUDE.md`.*
6. **Deterministic feedback.** Fixtures whose expected values were recorded
   independently, and a fake for each external service so tests never depend
   on someone else's uptime. *→ `fixtures/`, and the fake's own code.*
7. **What only a human may do.** *→ `CLAUDE.md`.*
8. **What must be green to merge**, by exact check name; whether merge is
   automatic once it is; and whether a human approval is also required (see
   below). *→ branch protection settings on the code host — **not in the
   repository**. Nothing in the repo will tell you these changed, or that a
   required check was quietly removed, so record what they should be
   somewhere in it.*
9. **The unit of work.** What an issue contains, and the criteria ID scheme.
   *→ an issue template.*
10. **Who looks at what landed, and how often.** Once merges are automatic,
    nobody sees the default branch unless something makes them. This is the
    cadence of the post-merge digest described in phase 3 — weekly, per
    slice, or whatever fits. *→ whatever produces it on a schedule. If the
    answer is "we will remember", it has no home and will not happen.*

Do not try to decide everything here. Capability that depends on evidence you
do not have yet — extra specialist reviewers, deployment gates — belongs in a
plan with an explicit trigger.

### Human review: on, off, or narrowed

Everything described above is machine. You can require a human approval on
top of it, and it is a genuine switch: branch protection sets how many
approvals a PR needs before the default branch will accept it. One or more
means a person must click approve; zero means the checks alone decide.
Automatic merge respects it either way — with approvals required, a fully
green PR waits for a human instead of landing.

There are three settings rather than two, and the middle one is usually the
right one:

- **Off.** The checks and the reviewers decide. Fastest, and nothing stands
  between a PR and the default branch except the gate — including for PRs
  that change the gate itself.
- **Narrowed.** Approval required only on the paths where being wrong is
  expensive: the spec, money-handling code, the review configuration. A
  code-owners file does this. Everything else merges on green.
- **On.** Every PR waits for a person.

Two things to know before choosing.

**A solo project cannot really use "on".** Most hosts will not let you
approve your own pull request, so a one-person repository with approvals
required can never satisfy the rule: every merge becomes an administrative
override. The setting then achieves nothing except training you to bypass
your own protections, which is worse than not having them. If you are alone,
the honest choices are *off* or *narrowed*.

**Ask whether anyone will actually read the diff**, not whether review sounds
prudent. An approval from someone who did not read is not review; it is
latency wearing review's clothes, and it leaves everyone believing changes
are being seen when they are not. If the honest answer is that nobody will
read them, turn it off and let the post-merge digest do the work instead.

A lighter option exists for one-off cases, without touching any setting: open
that PR as a **draft**. Drafts are not merged automatically and their
reviewers do not run, so marking it ready is itself the approval. Use this
when a single change needs a human and the project as a whole does not.

### Not yet specified

**An agent-written summary of each PR**, meant to be read by a person rather
than a reviewer — so someone not reading the diff can still follow what is
changing. An option, to be designed later.

## Phase 3 — implement

An agent takes the next criterion, works on a feature branch, opens a PR, and
the gate decides whether it lands.

Most of a project's ADRs get written here rather than in phase 1. Building is
what turns up the durable choices — a limit that has to be allocated, a
mechanism the plan assumed but never specified — and each one gets its ADR in
the PR that makes the choice, not afterwards.

### Escalate rather than invent

The single most important property of this phase. When an agent hits
something the plan does not determine, it must stop and ask, or record an
open question — not pick a plausible answer and continue.

Both outcomes produce a PR that looks fine. The difference is that a
surfaced question leaves a trace you can count, and a silently resolved one
leaves nothing at all. You cannot audit an absence, which is why this is a
rule in `CLAUDE.md` rather than advice here.

### When the gate is red

**Nothing in CI will fix it.** The checks, the verdicts, the gate and the
merge are all automatic; authoring the fix is not automated at all. The
reviewers are read-only by design — read tools, no write permission —
because a reviewer is processing an untrusted diff, and one that could write
to the repository would be a path straight into it.

So a red PR waits for a person to point an agent at it. If the session that
opened the PR is still running, it picks the findings up and continues; if it
was closed, the PR sits red until someone comes back to it. This part is not
fire-and-forget, and assuming otherwise is how work quietly stops.

If you want that loop closed, it is a separate job with its own identity and
tight bounds — one attempt, feature branch only, forbidden from touching the
workflows, the tests it has to pass, or the scope of the change. Do not close
it by giving the reviewers write access.

Otherwise: resolve the findings and push. The review runs again from scratch
against the new commit — there is nothing to reopen, reply to, or ask to be
reconsidered.

Three rules keep that loop honest.

**A re-review only counts after a substantive change.** Reviewers are not
deterministic, so pushing an empty commit and rerunning them until one
relents is available to you, and is not a resolution. If nothing changed that
addresses the finding, the finding is not addressed.

**Rejecting a finding does not unblock anything.** Explaining in the PR why a
finding does not apply is worth doing, and it will not turn the gate green:
the gate is mechanical and counts verdicts, not arguments. A `must_fix` the
author genuinely disagrees with is resolved by a human, not by persuasion.

**Stop after a bounded number of attempts.** If two or three honest attempts
have not cleared it, more attempts will not either. Escalate — because by
that point one of two things is true, and both are decisions rather than
work: the finding is right and the approach needs changing, or the reviewer's
prompt is wrong and needs fixing.

### Re-check the remaining criteria when work lands

One line in the PR description: which not-yet-built criteria this work
changed the answer for, or *"none affected"*. A criterion is affected if the
work made it impossible, made it unnecessary, or made it mean something
different from what was intended.

Criteria are guesses written before the work started, so the work is the
first real evidence about whether they were right — and unless there is a
line that has to be filled in, nobody notices a plan rotting until two slices
later. What to do about an affected criterion is a judgement, so it escalates
rather than being quietly rewritten.

### Front-load the questions

When you write a slice's criteria, mark the ones you already know will need a
person: a change to a settled rule, anything touching money or credentials, a
choice the plan deliberately left open. Put it in the criterion itself, and
name how the work stops there — *"the PR for D7 is opened as a draft;
marking it ready is the approval."*

You cannot decide those questions in advance. You can decide in advance where
they are, which turns an unpredictable interruption into a stop that happens
whether or not anyone remembers it. A mechanism that cannot proceed on its
own beats a note that relies on someone noticing.

### One agent per working tree

The other agents are running in other tmux sessions. You cannot see them,
they will not announce themselves, and nothing in git warns you that the
checkout you are working in is also someone else's.

Two agents sharing a checkout corrupt each other's work, quietly. A
`git add -A` in a shared tree sweeps whatever the other agent had in
progress into your commit, and a branch switch strands their changes on a
branch that was never meant for them. Neither produces an error.

Use `git worktree add` per agent. This costs one command and removes an
entire class of confusing failure.

### The post-merge digest

Once merges are automatic, nobody looks at the default branch. This is the
thing that makes someone look: a short list, produced on a schedule — weekly,
or once a slice — that a person actually reads. An agent can assemble it; a
human has to read it, or it is pointless.

Three things go in it.

**What merged.** The commits on the default branch since the last one, one
line each. So that somebody knows what changed without reading diffs.

**Findings that were waved through.** A `should_fix` does not block, so a PR
merges with it outstanding and nothing ever raises it again. Left alone these
accumulate into a pile of things the reviewers thought were wrong and nobody
ever decided about. List them, and decide each one: fix it, or drop it
deliberately.

**Bugs that got past review.** When you find a defect, record which PR
introduced it and whether any reviewer flagged it. If the reviewers approved
the PR that caused it, they missed it.

That last one is the only evidence you will ever get about whether the review
layer works. Without it, adding a reviewer, rewriting a prompt, or deciding
to trust the gate more are all guesses.
