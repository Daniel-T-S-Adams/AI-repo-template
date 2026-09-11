#!/usr/bin/env bash
# test-e2e.sh — End-to-end template validation (Layer 5)
# Usage: bash scripts/test-e2e.sh [--keep] [--skip-cleanup]
#
# Creates one real repository from AI-repo-template, verifies the first-agent,
# provenance, reconciliation, and security contracts, then deletes it on success.
# Requires: gh CLI authenticated with repo create/delete permissions.
set -uo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

PASS=0
FAIL=0
WARN=0
KEEP=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --keep) KEEP=true; shift ;;
    --skip-cleanup) KEEP=true; shift ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

OWNER=$(gh api user --jq '.login' 2>/dev/null)
if [[ -z "$OWNER" ]]; then
  echo -e "${RED}ERROR: gh CLI not authenticated${NC}"
  exit 1
fi

# Preflight the scope needed to clean up, BEFORE creating anything. Without
# this the suite creates a repository it cannot delete and leaks it. The
# header has always claimed this requirement; nothing enforced it.
if ! $KEEP; then
  if ! gh auth status 2>&1 | grep -q 'delete_repo'; then
    echo -e "${RED}ERROR: the gh token lacks the 'delete_repo' scope.${NC}" >&2
    echo "This suite creates a real repository and must be able to delete it." >&2
    echo "Grant it:  gh auth refresh -h github.com -s delete_repo" >&2
    echo "Or run with --keep to preserve test resources deliberately." >&2
    exit 1
  fi
fi

TEMPLATE_REPO="$OWNER/AI-repo-template"
TIMESTAMP=$(date +%s)
TEST_REPO="${OWNER}/e2e-test-template-${TIMESTAMP}"
REPO_NAME="e2e-test-template-${TIMESTAMP}"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
WORK_DIR=$(mktemp -d)

REPOS_TO_DELETE=()
CLEANUP_FAILED=0
DIRS_TO_DELETE=("$WORK_DIR")

# shellcheck disable=SC2317,SC2329
cleanup() {
  if $KEEP; then
    echo ""
    echo -e "${YELLOW}--keep flag set. Preserving test resources:${NC}"
    for r in "${REPOS_TO_DELETE[@]}"; do
      echo "  https://github.com/$r"
    done
    echo "  Local: $WORK_DIR"
    return
  fi

  echo ""
  echo "Cleaning up..."
  for r in "${REPOS_TO_DELETE[@]}"; do
    if gh repo delete "$r" --yes 2>/dev/null; then
      echo "  Deleted: $r"
    else
      echo -e "  ${RED}LEAKED: $r could not be deleted${NC}" >&2
      echo "  Delete it manually: gh repo delete $r --yes" >&2
      CLEANUP_FAILED=1
    fi
  done
  for d in "${DIRS_TO_DELETE[@]}"; do
    rm -rf "$d" 2>/dev/null
  done

  # The gate lives HERE, not in the script body. cleanup() runs only as the
  # EXIT trap, which fires after the body has already selected its exit
  # status, so a check down there reads CLEANUP_FAILED before this function
  # has ever assigned it. `exit` from inside an EXIT trap overrides the
  # status the body chose — that is what makes a leak fail the run.
  if [[ $CLEANUP_FAILED -ne 0 ]]; then
    echo -e "${RED}Test resources were leaked — see above. Failing the run.${NC}" >&2
    exit 1
  fi
}
trap cleanup EXIT

pass() { echo -e "  ${GREEN}PASS${NC}  $1"; PASS=$((PASS + 1)); }
fail() { echo -e "  ${RED}FAIL${NC}  $1"; FAIL=$((FAIL + 1)); }
warn() { echo -e "  ${YELLOW}WARN${NC}  $1"; WARN=$((WARN + 1)); }
header() { echo ""; echo -e "${CYAN}=== $1 ===${NC}"; }

echo ""
echo "============================================"
echo "  AI-repo-template E2E Test Suite (Layer 5)"
echo "  Owner: $OWNER"
echo "  Template: $TEMPLATE_REPO"
echo "  Work dir: $WORK_DIR"
echo "  $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "============================================"

# ============================================================
# TEST 5.1: Create from Template → First-Agent Contract
# ============================================================
header "5.1: Create from Template — First-Agent Contract"

echo "  Creating repository from template..."
# Register for cleanup the instant the repository exists, NOT after the clone.
# Anything between creation and registration is a window where a live
# repository is untracked: cleanup() iterates an empty list, the leak gate
# never fires, and the suite reports a create failure while the repository
# persists unmentioned. Cloning a --private repo depends on git credentials,
# so that window is real, not theoretical.
if gh repo create "$TEST_REPO" --template "$TEMPLATE_REPO" --private >/dev/null 2>&1; then
  REPOS_TO_DELETE+=("$TEST_REPO")
  sleep 3
  if git clone "https://github.com/$TEST_REPO.git" "$WORK_DIR/$REPO_NAME" >/dev/null 2>&1; then
    pass "Repository created from template: $TEST_REPO"
  else
    fail "Created $TEST_REPO but could not clone it (git credentials for HTTPS?)"
    TEST_REPO_SKIP=true
  fi
else
  fail "Failed to create repository from template"
  TEST_REPO_SKIP=true
fi

if [[ "${TEST_REPO_SKIP:-}" != "true" ]]; then
  cd "$WORK_DIR/$REPO_NAME" || { fail "Failed to enter cloned repository"; exit 1; }

  essential_ok=true
  for f in README.md CLAUDE.md AGENTS.md .repo-template.yaml \
           docs/INTAKE.md docs/template/TEMPLATE-UPGRADE.md \
           .claude/commands/bootstrap.md .claude/commands/upgrade-template.md \
           .gitattributes .gitignore scripts/secure-repo.sh \
           templates/hooks/setup-hooks.sh templates/hooks/pre-commit-secrets.sh.template; do
    if [[ ! -f "$f" ]]; then
      fail "Missing after template creation: $f"
      essential_ok=false
    fi
  done
  if $essential_ok; then
    pass "First-agent, provenance, reconciliation, and security files transfer"
  fi

  if grep -q 'Derived-repository mode' CLAUDE.md && \
     grep -q 'Derived-repository mode' AGENTS.md; then
    pass "Claude and Codex entry files detect derived-repository mode"
  else
    fail "Derived-repository mode missing from agent entry files"
  fi

  # ADR 008: the intake is additive. It enumerates what is optional rather
  # than asking an agent to classify what it inherited, states a security
  # floor that is never optional, and takes the project from the current
  # session before asking the user to repeat themselves.
  if grep -q 'Optional contents' docs/INTAKE.md && \
     grep -q 'Never optional' docs/INTAKE.md && \
     grep -q 'The current session' docs/INTAKE.md; then
    pass "intake carries the additive contract and the security floor"
  else
    fail "intake contract is incomplete"
  fi

  # Inverted guard, matching validate-template.yml: the subtractive frame
  # must not come back. Without this the two checks can drift into
  # contradicting each other, which is exactly how this file went stale.
  if grep -q 'KEEP / ADAPT / REMOVE / DEFER' docs/INTAKE.md; then
    fail "intake reintroduces the classification frame superseded by ADR 008"
  else
    pass "intake does not reintroduce the subtractive frame"
  fi

  if grep -q '^baseline_id: slot-intake-v1$' .repo-template.yaml && \
     grep -q 'strategy: semantic-reconciliation' .repo-template.yaml; then
    pass "Template provenance marker carries the current reconciliation baseline"
  else
    fail "Template provenance marker is missing or incorrect"
  fi

  if grep -qi 'three-way model' docs/template/TEMPLATE-UPGRADE.md && \
     grep -q 'docs/template/TEMPLATE-UPGRADE.md' .claude/commands/upgrade-template.md; then
    pass "Template upgrade guidance and Claude entrypoint transfer"
  else
    fail "Template upgrade reconciliation contract is incomplete"
  fi

  if grep -q 'docs/INTAKE.md' .claude/commands/bootstrap.md && \
     grep -q 'docs/INTAKE.md' .claude/commands/init-template.md && \
     ! grep -qE 'Quick setup|Gather Project Information|Ask for project name' .claude/commands/init-template.md; then
    pass "Bootstrap is canonical and legacy initializer is compatibility-only"
  else
    fail "Legacy interactive initializer behavior is still active"
  fi

  if grep -qE 'Client.*API Server|npm run dev|DATABASE_URL|NODE_ENV|Production.*main branch' \
      CLAUDE.md AGENTS.md .env.example; then
    fail "Speculative application defaults exist in first-agent surfaces"
  else
    pass "First-agent surfaces remain stack- and architecture-neutral"
  fi

  if [[ ! -f .git/hooks/pre-commit ]]; then
    pass "Local hooks correctly do not transfer through GitHub templates"
  else
    warn "Unexpected pre-commit hook exists in fresh clone"
  fi

  cd "$REPO_ROOT" || exit 1
fi

# ============================================================
# TEST 5.2: Security Baseline on a Fresh Derived Repository
# ============================================================
header "5.2: Security Baseline"

if [[ "${TEST_REPO_SKIP:-}" != "true" ]]; then
  cd "$WORK_DIR/$REPO_NAME" || exit 1

  echo "  Running secure-repo.sh..."
  secure_output=$(bash scripts/secure-repo.sh 2>&1) || true
  if echo "$secure_output" | grep -q 'SCORECARD'; then
    pass "secure-repo.sh produces a scorecard on a fresh derived repo"
  else
    fail "secure-repo.sh did not produce a scorecard"
  fi

  echo "  Running setup-hooks.sh..."
  if bash templates/hooks/setup-hooks.sh >/dev/null 2>&1 && [[ -x .git/hooks/pre-commit ]]; then
    pass "setup-hooks.sh installs an executable pre-commit hook"
  else
    fail "setup-hooks.sh did not install a working pre-commit hook"
  fi

  echo "const key = 'sk-ant-e2etest123456789';" > test-e2e-secret.js
  git add -f test-e2e-secret.js >/dev/null 2>&1
  if bash .git/hooks/pre-commit >/dev/null 2>&1; then
    fail "Pre-commit hook should block the secret fixture"
  else
    pass "Pre-commit hook blocks the secret fixture"
  fi
  git reset HEAD test-e2e-secret.js >/dev/null 2>&1
  rm -f test-e2e-secret.js

  echo "const hello = 'world';" > test-e2e-clean.js
  git add -f test-e2e-clean.js >/dev/null 2>&1
  if bash .git/hooks/pre-commit >/dev/null 2>&1; then
    pass "Pre-commit hook allows a clean fixture"
  else
    fail "Pre-commit hook incorrectly blocked a clean fixture"
  fi
  git reset HEAD test-e2e-clean.js >/dev/null 2>&1
  rm -f test-e2e-clean.js

  labels_output=$(bash scripts/labels.sh 2>&1) || true
  if echo "$labels_output" | grep -qi 'label'; then
    pass "labels.sh remains usable before project intake"
  else
    warn "labels.sh produced no recognizable output"
  fi

  cd "$REPO_ROOT" || exit 1
fi

# ============================================================
# TEST 5.3: Template Truthfulness Before Project Intake
# ============================================================
header "5.3: Pre-Intake Truthfulness"

if [[ "${TEST_REPO_SKIP:-}" != "true" ]]; then
  cd "$WORK_DIR/$REPO_NAME" || exit 1

  if grep -q 'The Golden Path' README.md && \
     grep -q 'Agent inside a repository created from this template' README.md; then
    pass "README identifies the derived-repository golden path"
  else
    fail "README does not expose the first-agent golden path"
  fi

  if grep -q 'AI-repo-template source' docs/ARCHITECTURE.md && \
     ! grep -q 'Client.*API Server' docs/ARCHITECTURE.md; then
    pass "Architecture document describes the template, not a fictitious app"
  else
    fail "Architecture document contains misleading application architecture"
  fi

  if grep -q 'intentionally empty' .env.example && \
     ! grep -qE 'DATABASE_URL|API_KEY|NODE_ENV|PORT=' .env.example; then
    pass ".env.example is intentionally stack-neutral"
  else
    fail ".env.example implies project-specific variables before intake"
  fi

  cd "$REPO_ROOT" || exit 1
fi

# ============================================================
# TEST 5.4: Template Baseline Compatibility
# ============================================================
header "5.4: Template Baseline Compatibility"

if [[ "${TEST_REPO_SKIP:-}" != "true" ]]; then
  cd "$WORK_DIR/$REPO_NAME" || exit 1

  local_baseline=$(awk -F': *' '$1 == "baseline_id" {print $2; exit}' .repo-template.yaml)
  template_baseline=$(gh api -H 'Accept: application/vnd.github.raw+json' \
    "repos/$TEMPLATE_REPO/contents/.repo-template.yaml" 2>/dev/null | \
    awk -F': *' '$1 == "baseline_id" {print $2; exit}')

  if [[ -n "$local_baseline" && "$local_baseline" = "$template_baseline" ]]; then
    pass "Fresh derived repository records the current template baseline"
  else
    fail "Fresh derived repository baseline does not match the source template"
  fi

  if grep -q 'Template baseline is current' .github/workflows/check-template-drift.yml && \
     ! grep -q 'git hash-object' .github/workflows/check-template-drift.yml; then
    pass "Compatibility workflow checks baseline provenance, not exact project file hashes"
  else
    fail "Compatibility workflow still assumes downstream files should match the template"
  fi

  cd "$REPO_ROOT" || exit 1
fi

# ============================================================
# TEST 5.5: Cross-Repo Compliance Audit
# ============================================================
header "5.5: Cross-Repo Compliance Audit"

echo "  Auditing $TEMPLATE_REPO (self)..."
self_output=$(bash scripts/audit-compliance.sh "$TEMPLATE_REPO" 2>/dev/null) || true

if echo "$self_output" | python3 -c "
import sys, json
d = json.load(sys.stdin)
r = d['repos'][0]
score = r['compliance_score']
grade = r['grade']
print(f'  Score: {score}% ({grade})')
sys.exit(0 if score >= 95 else 1)
" 2>/dev/null; then
  pass "AI-repo-template self-audit is at least 95%"
else
  warn "AI-repo-template self-audit is below 95%"
fi

# ============================================================
# SUMMARY
# ============================================================

echo ""
echo "============================================"
TOTAL=$((PASS + FAIL + WARN))
echo -e "  Results: ${GREEN}$PASS pass${NC} | ${RED}$FAIL fail${NC} | ${YELLOW}$WARN warn${NC}"
echo "  Total: $TOTAL checks"

if [[ $FAIL -eq 0 ]]; then
  echo -e "  ${GREEN}ALL E2E TESTS PASSED${NC}"
else
  echo -e "  ${RED}$FAIL FAILURE(S)${NC}"
fi
echo "============================================"
echo ""

exit "$FAIL"
