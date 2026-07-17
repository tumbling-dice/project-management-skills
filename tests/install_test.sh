#!/usr/bin/env bash
set -euo pipefail

# This test protects the distinct current discovery roots for skills and Codex custom agents.
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root="$(mktemp -d)"
trap 'rm -rf "$test_root"' EXIT

# Assert that a dry-run line contains the expected destination without depending on source paths.
# Args: complete output and expected substring. Returns: zero on match, one with a diagnostic otherwise.
assert_contains() {
  local output="$1"
  local expected="$2"

  if [[ "$output" != *"$expected"* ]]; then
    echo "expected output to contain: $expected" >&2
    return 1
  fi
}

output="$(HOME="$test_root/home" CODEX_HOME="$test_root/codex" "$repo_root/scripts/install.sh" --dry-run)"

assert_contains "$output" "$test_root/home/.agents/skills/wf-explore"
assert_contains "$output" "$test_root/home/.agents/skills/review-tests"
assert_contains "$output" "$test_root/codex/agents/project_doc_auditor.toml"
assert_contains "$output" "$test_root/codex/agents/test_reviewer.toml"

if [[ -e "$test_root/home/.agents" || -e "$test_root/codex/agents" ]]; then
  echo "dry-run created installation directories" >&2
  exit 1
fi
