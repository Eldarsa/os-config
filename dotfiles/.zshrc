# ~/.zshrc — symlinked from os-config/dotfiles/.zshrc
# Keep this file small. When a section grows past ~20 lines, split it into
# dotfiles/.zsh/<section>.zsh and source it from here.

# ---- history ---------------------------------------------------------------
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt HIST_IGNORE_DUPS HIST_IGNORE_SPACE SHARE_HISTORY INC_APPEND_HISTORY

# ---- shell behavior --------------------------------------------------------
setopt AUTO_CD                 # `cd` is implied when typing a directory name
setopt INTERACTIVE_COMMENTS    # allow # comments in interactive shell
setopt NO_BEEP

# ---- completion ------------------------------------------------------------
autoload -Uz compinit && compinit
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'   # case-insensitive

# ---- prompt ----------------------------------------------------------------
# Minimal prompt: user@host  cwd (git branch)  $
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' (%b)'
setopt PROMPT_SUBST
PROMPT='%F{cyan}%n@%m%f %F{yellow}%~%f%F{green}${vcs_info_msg_0_}%f %# '

# ---- aliases ---------------------------------------------------------------
alias ll='ls -lah --color=auto'
alias la='ls -A --color=auto'
alias ..='cd ..'
alias ...='cd ../..'
alias g='git'
alias gs='git status'
alias gd='git diff'
alias gl='git log --oneline --graph --decorate -20'

# ---- path ------------------------------------------------------------------
# Add ~/.local/bin if it exists (used by pipx, mise shims, etc.)
[ -d "$HOME/.local/bin" ] && export PATH="$HOME/.local/bin:$PATH"

# ---- tool integrations -----------------------------------------------------
# mise: auto-switch language runtimes per directory.
command -v mise >/dev/null && eval "$(mise activate zsh)"
# direnv: auto-load .envrc env vars per directory.
command -v direnv >/dev/null && eval "$(direnv hook zsh)"

# ---- environment -----------------------------------------------------------
# Pick the best available editor (nvim wins; fall back to vim, then nano).
for _ed in nvim vim nano; do
  if command -v "$_ed" >/dev/null; then
    export EDITOR="$_ed" VISUAL="$_ed"
    break
  fi
done
unset _ed

# ---- local overrides -------------------------------------------------------
# Anything machine-specific (API keys, host-specific paths) goes here, NOT in
# the repo. This file is gitignored from the os-config repo's perspective
# because it lives outside the repo.
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
