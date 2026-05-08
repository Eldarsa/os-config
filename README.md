# os-config

My reproducible dev environment, grown one piece at a time.

## Bootstrap a fresh machine

```bash
sudo apt-get update && sudo apt-get install -y git
git clone https://github.com/<you>/os-config.git ~/os-config
cd ~/os-config
./bootstrap.sh
```

`bootstrap.sh` runs every script in `install/` in alphabetical order. Each
script must be **idempotent** — safe to run twice. Re-run `./bootstrap.sh`
any time to bring a machine back into the desired state.

## Layout

```
bootstrap.sh      # entry point — runs install/*.sh in order
lib/common.sh     # shared helpers (log, ensure_pkg, link_dotfile)
install/          # modular setup steps, numbered for ordering
  00-base.sh      # apt update + essential packages
dotfiles/         # files symlinked into $HOME
```

## Adding a new step

1. Create `install/NN-thing.sh` (pick a number that puts it in the right order).
2. Use helpers from `lib/common.sh` — don't call `apt-get install` directly,
   use `ensure_pkg` so reruns are quiet.
3. Test by re-running `./bootstrap.sh` — should be a no-op the second time.
