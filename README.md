# os-config

Reproducible dev environment for a Linux VPS, built up one piece at a time.
Clone the repo, run one script, get a complete setup: shell, editor,
runtimes, containers, firewall, AI tooling.

## Bootstrap a fresh machine

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/Eldarsa/os-config.git ~/os-config
cd ~/os-config
./bootstrap.sh
```

`bootstrap.sh` sources every script in `install/` in alphabetical order.
Re-running is safe and silent — every step checks "is this already done?"
before doing anything (idempotency).

## Layout

```
bootstrap.sh          # entry point — sources install/*.sh in order
lib/common.sh         # shared helpers: log, ok, warn, err, ensure_pkg, link_dotfile
install/              # modular setup steps, numbered by category
  00-base.sh          # apt update/upgrade + essential packages
  05-workspace.sh     # ~/code workspace directory
  10-git.sh           # git config + identity prompt + ed25519 SSH key
  10-shell.sh         # zsh + login shell switch + .zshrc link
  15-tmux.sh          # tmux + fzf + tpm + sessionizer
  20-mise.sh          # mise (runtime version manager) + Node LTS
  25-direnv.sh        # direnv (per-directory env vars)
  30-docker.sh        # Docker engine + compose plugin + group membership
  35-firewall.sh      # ufw default-deny + SSH (limited) + tailscale interface
  40-neovim.sh        # neovim from upstream + LazyVim starter
  45-lazygit.sh       # lazygit from upstream
  50-claude-code.sh   # Claude Code via npm + user-level config link
  60-claude-skills.sh # skills declared in skills.list, installed via skills CLI
dotfiles/             # files symlinked into $HOME
  .zshrc              # shell config (sourced .zshrc.local at the end)
  .gitconfig          # shared git config (includes .gitconfig.local)
  .tmux.conf          # tmux config + tpm plugin declarations
  .local/bin/sessionizer    # tmux session picker (Ctrl-f / prefix+f)
  .config/mise/config.toml  # global mise tool versions
  .claude/settings.json     # Claude Code permissions, plugins, prefs
  .claude/CLAUDE.md         # user-level memory
  .claude/skills.list       # declarative skill manifest
```

### Numbering convention

Soft categories — adjust freely as you add things:

| Range | Purpose                          |
|-------|----------------------------------|
| 00–09 | Base system, workspace           |
| 10–19 | Shell, terminal, version control |
| 20–29 | Runtimes, env management         |
| 30–39 | System services (docker, firewall) |
| 40–49 | Editor + git tooling             |
| 50–59 | Applications                     |
| 60–69 | User-level extensions            |

## Patterns

### Install steps vs dotfiles

- `install/NN-foo.sh` does *one-time wiring* — installs a package, starts a
  service, creates a symlink. Idempotent.
- `dotfiles/X` is *live config*. Edit it and changes are immediate (it's
  symlinked into `$HOME`). No re-bootstrap needed.

### `.local` override pattern

The committed file holds defaults, the `.local` sibling holds machine-specific
secrets and overrides. The default file sources the `.local` file if present.
Three places this shows up:

| Committed         | Per-machine (gitignored) |
|-------------------|--------------------------|
| `.zshrc`          | `~/.zshrc.local`         |
| `.gitconfig`      | `~/.gitconfig.local`     |
| `.envrc` (project) | `.envrc.local` (project) |

### Idempotency rules

Every install step:

- Checks if the desired state already exists before changing anything.
- Uses `ensure_pkg` instead of `apt-get install` so re-runs are silent.
- Uses `link_dotfile` instead of `ln -s` so existing files are backed up
  rather than overwritten.

If you can't run the script twice without effects, it's not done.

## Adding a new install step

1. Create `install/NN-thing.sh` (pick a number that places it in the right
   ordering relative to dependencies).
2. Source helpers automatically — `bootstrap.sh` has already done that.
3. Use `ensure_pkg`, `link_dotfile`, `log`, `ok`, `warn`, `err`.
4. Run `./bootstrap.sh` twice. Second run should produce only `ok` messages.
5. `chmod +x install/NN-thing.sh`.

## Adding a new dotfile

1. Drop the file under `dotfiles/<path>` mirroring its location in `$HOME`
   (e.g. `dotfiles/.config/foo/bar.toml` → `~/.config/foo/bar.toml`).
2. Add a `link_dotfile <src> <dest>` call in the appropriate install step.

## Post-bootstrap manual steps

Some things can't be (or shouldn't be) automated. Do these once:

| Step | What |
|------|------|
| **Add SSH key to GitHub** | `10-git.sh` prints the public key — paste it into GitHub SSH settings. |
| **Authenticate Claude Code** | First `claude` run needs OAuth. SSH into the VPS with `LocalForward` for the OAuth port (laptop-side `~/.ssh/config`), then run `claude` and complete login in your laptop browser. |
| **Tmux plugins** | First tmux launch: `prefix + I` to install plugins via tpm. |
| **Hetzner Cloud Firewall** | Configure in Hetzner Console: allow `22/tcp` and ICMP inbound, deny everything else. ufw is the inner layer; Hetzner is the outer. |
| **Fill in `~/.claude/CLAUDE.md`** | The default is a placeholder. Add your real preferences. |

## Workflow notes

- **Tailscale** handles connectivity to the VPS — `http://jarvis:3010` reaches
  any dev server bound to that port. SSH port forwarding only needed for
  OAuth flows (Claude Code login, OAuth-based MCPs).
- **Sessionizer** (`Ctrl-f` in shell, `prefix+f` in tmux) picks a project under
  `~/code` and attaches/switches to a tmux session named after it.
- **mise + direnv** together make per-project state automatic: mise switches
  Node/Python versions on `cd`, direnv loads env vars from `.envrc` (or `.env`
  via the `dotenv_if_exists` helper).
- **Firewall model**: public surface = SSH only. Tailscale interface is
  trusted. Dev servers binding to `0.0.0.0` are reachable via Tailscale but
  invisible to the public internet.
