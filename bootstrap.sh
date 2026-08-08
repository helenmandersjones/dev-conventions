#!/usr/bin/env bash
# bootstrap.sh — install dev-conventions symlinks into a project.
#
# Usage:
#   ./dev-conventions/bootstrap.sh <project-dir>
#
# Idempotent: re-running is safe; existing correct symlinks are left alone.
# Refuses to clobber existing real files/directories — move or remove them first.

set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "usage: $0 <project-dir>" >&2
  exit 2
fi

project_dir=$(cd "$1" && pwd)
conventions_dir=$(cd "$(dirname "$0")" && pwd)

if [[ "$(dirname "$project_dir")" != "$(dirname "$conventions_dir")" ]]; then
  echo "warning: $project_dir and $conventions_dir are not siblings." >&2
  echo "         Symlinks will still work but the relative target assumes siblings." >&2
fi

# Each entry: <link_path_within_project>:<target_path_within_dev_conventions>
# Skills live once under skills/; Cursor and Codex each get a discovery symlink.
links=(
  "AGENTS.md:AGENTS.md"
  ".cursor/rules:cursor/rules"
  ".cursor/skills:skills"
  ".agents/skills:skills"
  "docs/conventions:docs/conventions"
)

for entry in "${links[@]}"; do
  link_rel="${entry%%:*}"
  target_sub="${entry##*:}"
  link_path="$project_dir/$link_rel"

  # Build relative target: one '../' per component in link_rel (escapes from
  # link's parent dir up to the project's parent), then 'dev-conventions/...'.
  IFS='/' read -ra parts <<< "$link_rel"
  prefix=""
  for ((i=0; i<${#parts[@]}; i++)); do prefix+="../"; done
  target_rel="${prefix}dev-conventions/$target_sub"

  mkdir -p "$(dirname "$link_path")"

  if [[ -L "$link_path" ]]; then
    current=$(readlink "$link_path")
    if [[ "$current" == "$target_rel" ]]; then
      echo "  ok   $link_rel -> $target_rel"
      continue
    fi
    echo "  fix  $link_rel (was: $current)"
    rm "$link_path"
  elif [[ -e "$link_path" ]]; then
    echo "error: $link_path exists and is not a symlink." >&2
    echo "       Move or remove it first, then re-run." >&2
    exit 1
  fi

  ln -s "$target_rel" "$link_path"
  echo "  link $link_rel -> $target_rel"
done

# docs/tasks/ — per-project task tracker (required by agent rules; committed in each repo)
scaffold_tasks="$conventions_dir/scaffold/docs/tasks"
project_tasks="$project_dir/docs/tasks"

if [[ ! -d "$scaffold_tasks" ]]; then
  echo "error: missing scaffold at $scaffold_tasks" >&2
  exit 1
fi

if [[ ! -d "$project_tasks" ]]; then
  mkdir -p "$(dirname "$project_tasks")"
  cp -R "$scaffold_tasks" "$project_tasks"
  echo "  scaffold docs/tasks/ (new)"
else
  while IFS= read -r -d '' item; do
    rel="${item#"$scaffold_tasks"/}"
    dest="$project_tasks/$rel"
    if [[ ! -e "$dest" ]]; then
      mkdir -p "$(dirname "$dest")"
      cp -R "$item" "$dest"
      echo "  add    docs/tasks/$rel"
    fi
  done < <(find "$scaffold_tasks" -mindepth 1 -print0)
fi

echo
echo "Done. Add these to $project_dir/.gitignore if not already present:"
echo "  /AGENTS.md"
echo "  /.cursor/rules"
echo "  /.cursor/skills"
echo "  /.agents/skills"
echo "  /docs/conventions"
echo
echo "Commit docs/tasks/ in the project repo (it is not symlinked)."
