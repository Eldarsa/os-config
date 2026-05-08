#!/usr/bin/env bash
# Install Claude Code globally via npm and link user-level config from dotfiles.
# Requires node from 20-mise.sh — run that first (and reload your shell so
# `mise activate` puts node on PATH).

if ! command -v node >/dev/null; then
  err "node not found on PATH"
  err "  make sure 20-mise.sh has run and reload your shell ('exec zsh') before this step"
  return 1
fi

if command -v claude >/dev/null; then
  ok "claude code already installed ($(claude --version 2>/dev/null | head -1))"
else
  log "installing @anthropic-ai/claude-code globally"
  npm install -g @anthropic-ai/claude-code
fi

# User-level Claude Code config. Per-project config goes in each repo's
# own CLAUDE.md / .mcp.json — not here.
link_dotfile .claude/settings.json .claude/settings.json
link_dotfile .claude/CLAUDE.md     .claude/CLAUDE.md

log "first 'claude' run will prompt you to authenticate"
