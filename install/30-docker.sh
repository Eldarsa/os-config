#!/usr/bin/env bash
# Install Docker Engine + Compose plugin from Docker's official apt repo,
# enable the daemon, and add the current user to the docker group.

if command -v docker >/dev/null; then
  ok "docker already installed ($(docker --version))"
else
  log "adding Docker's official apt repo"

  # /etc/os-release sets ID (ubuntu/debian) and VERSION_CODENAME (jammy/bookworm/...)
  # shellcheck disable=SC1091
  . /etc/os-release

  sudo install -m 0755 -d /etc/apt/keyrings
  if [ ! -f /etc/apt/keyrings/docker.asc ]; then
    sudo curl -fsSL "https://download.docker.com/linux/$ID/gpg" \
      -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
  fi

  arch="$(dpkg --print-architecture)"
  echo "deb [arch=$arch signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/$ID $VERSION_CODENAME stable" \
    | sudo tee /etc/apt/sources.list.d/docker.list >/dev/null

  log "installing docker engine + compose plugin"
  sudo apt-get update -y
  sudo apt-get install -y \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
fi

# Daemon should be enabled at boot and currently running.
if ! systemctl is-enabled --quiet docker; then
  log "enabling docker service at boot"
  sudo systemctl enable docker
fi
if ! systemctl is-active --quiet docker; then
  log "starting docker service"
  sudo systemctl start docker
fi

# Group membership lets us run `docker` without sudo.
if id -nG "$USER" | grep -qw docker; then
  ok "$USER already in docker group"
else
  log "adding $USER to docker group"
  sudo usermod -aG docker "$USER"
  warn "log out and back in (or run 'newgrp docker') before docker works without sudo"
fi
