# One command defines a valid change.
#
# `make check` is the contract referred to by CLAUDE.md rule 4 and by
# docs/INTAKE.md slot 5. It builds, lints and tests, and every target
# propagates failure. Masking a required check is forbidden — `|| true`, a
# swallowed exit code, or a test that skips itself when a dependency is
# missing all turn a real failure into a green run.
#
# Unconfigured targets FAIL rather than doing nothing. A `make check` that
# passes because nothing was configured is worse than one that errors: it
# reports "clean" for the same reason a genuinely clean tree does. Fill the
# slots below, or delete the target and remove it from `check`.
#
# Prove it can fail. Before trusting a green run, break something on purpose
# and confirm `make check` goes red. A check that cannot detect anything
# reports success identically to one that found nothing wrong.

.PHONY: check fmt-check fmt lint test help

# «slot: the command that verifies formatting, e.g.
#   cargo fmt --all --check   /   npm run format:check   /   ruff format --check . »
FMT_CHECK_CMD ?=

# «slot: the command that reformats in place, e.g.
#   cargo fmt --all   /   npm run format   /   ruff format . »
FMT_CMD ?=

# «slot: static analysis, with warnings treated as errors, e.g.
#   cargo clippy --workspace --all-targets -- -D warnings
#   npm run lint -- --max-warnings 0
#   ruff check . »
LINT_CMD ?=

# «slot: the test suite, e.g.
#   cargo test --workspace   /   npm test   /   pytest »
TEST_CMD ?=

# «slot: add project-specific gates to `check` as their own targets —
# schema validation, a credential-boundary scan, a fixture-drift check.
# Each one needs a positive control: prove the checker can fail before a
# clean result from it means anything. »

check: fmt-check lint test
	@echo "==> check: all gates passed"

define run_or_fail
@if [ -z "$(2)" ]; then \
	echo ""; \
	echo "make: $(3) is not configured." >&2; \
	echo "Set $(1) at the top of the Makefile, or remove this target from 'check'." >&2; \
	echo "An unconfigured gate fails rather than passing silently: a green" >&2; \
	echo "'make check' must mean the gates ran, not that they were absent." >&2; \
	echo ""; \
	exit 1; \
fi; \
echo "==> $(2)"; \
$(2)
endef

fmt-check:
	$(call run_or_fail,FMT_CHECK_CMD,$(FMT_CHECK_CMD),the formatting check)

fmt:
	$(call run_or_fail,FMT_CMD,$(FMT_CMD),the formatter)

lint:
	$(call run_or_fail,LINT_CMD,$(LINT_CMD),the linter)

test:
	$(call run_or_fail,TEST_CMD,$(TEST_CMD),the test suite)

help:
	@echo "check      Run every gate. This is the contract; it must pass before pushing."
	@echo "fmt        Reformat in place."
	@echo "fmt-check  Verify formatting without changing files."
	@echo "lint       Static analysis, warnings as errors."
	@echo "test       Run the test suite."
