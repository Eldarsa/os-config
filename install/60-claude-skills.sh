#!/usr/bin/env bash
# Install Claude Code skills declared in dotfiles/.claude/skills.list via the
# `skills` CLI (https://skills.sh). Idempotent: skips skills already on disk.
# Requires node from 20-mise.sh (npx).

if ! command -v npx >/dev/null; then
  err "npx not found — make sure 20-mise.sh has run and node is on PATH"
  return 1
fi

manifest="$REPO_DIR/dotfiles/.claude/skills.list"
if [ ! -f "$manifest" ]; then
  warn "$manifest not found — nothing to install"
  return 0
fi

while IFS= read -r line || [ -n "$line" ]; do
  # strip leading whitespace, skip comments and blanks
  line="${line#"${line%%[![:space:]]*}"}"
  case "$line" in ''|\#*) continue ;; esac

  # split on whitespace: first token is name, second is source
  name="${line%%[[:space:]]*}"
  rest="${line#"$name"}"
  rest="${rest#"${rest%%[![:space:]]*}"}"
  source="${rest%%[[:space:]]*}"

  if [ -d "$HOME/.claude/skills/$name" ]; then
    ok "skill already installed: $name"
    continue
  fi

  if [ -z "$source" ]; then
    log "installing skill: $name (resolving via skills registry)"
    npx -y skills@latest add "$name" -y
  else
    log "installing skill: $name (from $source)"
    npx -y skills@latest add "$source" --skill "$name" -y
  fi
done < "$manifest"
