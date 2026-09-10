<!-- Every PR traces to a unit of work. Start the body with "Closes #<issue>",
or "Advances #<issue>" when criteria remain open. -->

## What

<!-- What changed and why, in terms a reviewer who reads only this section
could act on. -->

## Definition of done

- [ ] Scope stayed within the stated goal and non-goals
- [ ] `make check` passes with no masked failures
- [ ] Changed behaviour and its important failure path have tests
- [ ] Affected `docs/spec/` files and ADRs updated **in this PR**, not a follow-up
- [ ] No secrets, credentials, or environment files added
- [ ] AI review findings resolved, or explicitly rejected with a reason below

## Evidence

<!-- Test output, measurements, a live-run timeline — what a reader needs in
order to trust this change without re-running it. -->

## Criteria this changed the answer for

<!-- Which not-yet-built acceptance criteria did this work make impossible,
unnecessary, or different in meaning? "None affected" is a valid answer, but
it has to be written. Criteria are guesses made before the work started, and
this is the first real evidence about whether they were right. -->

None affected.

## Rejected review findings

<!-- finding → why it does not apply. Deleting this section means "none".

Rejecting a finding does not unblock the merge: the gate counts verdicts, not
arguments. A must_fix you genuinely disagree with is resolved by a human, not
by persuasion, and not by re-running a nondeterministic reviewer until it
relents. -->
