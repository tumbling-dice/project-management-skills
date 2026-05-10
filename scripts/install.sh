#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
codex_home="${CODEX_HOME:-$HOME/.codex}"
skills_dir="$codex_home/skills"
agents_dir="$codex_home/agents"
dry_run=0

usage() {
  cat <<'USAGE'
Usage: scripts/install.sh [--dry-run]

Installs project-management skills and common custom agents for Codex.

Behavior:
  - skills are symlinked into $CODEX_HOME/skills or ~/.codex/skills
  - agents are symlinked into $CODEX_HOME/agents or ~/.codex/agents
  - existing paths are not overwritten
USAGE
}

for arg in "$@"; do
  case "$arg" in
    --dry-run)
      dry_run=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $arg" >&2
      usage >&2
      exit 2
      ;;
  esac
done

is_skill_dir() {
  local path="$1"
  [[ -d "$path" ]] || return 1
  [[ -f "$path/SKILL.md" ]] || return 1
}

link_path() {
  local src="$1"
  local dest="$2"

  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "skip existing: $dest"
    return 0
  fi

  if [[ "$dry_run" -eq 1 ]]; then
    echo "link: $dest -> $src"
    return 0
  fi

  ln -s "$src" "$dest"
  echo "linked: $dest -> $src"
}

if [[ "$dry_run" -eq 1 ]]; then
  echo "dry-run: no filesystem changes"
else
  mkdir -p "$skills_dir" "$agents_dir"
fi

while IFS= read -r skill_dir; do
  name="$(basename "$skill_dir")"
  link_path "$skill_dir" "$skills_dir/$name"
done < <(
  find "$repo_root" -mindepth 1 -maxdepth 1 -type d \
    ! -name '.*' \
    ! -name agents \
    ! -name scripts \
    -print | sort | while IFS= read -r dir; do
      if is_skill_dir "$dir"; then
        printf '%s\n' "$dir"
      fi
    done
)

if [[ -d "$repo_root/agents" ]]; then
  while IFS= read -r agent_file; do
    name="$(basename "$agent_file")"
    link_path "$agent_file" "$agents_dir/$name"
  done < <(find "$repo_root/agents" -maxdepth 1 -type f -name '*.toml' -print | sort)
fi
