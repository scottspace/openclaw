#!/usr/bin/env bash
# workspace-boot.sh — Clone or update the workspace repo on container start.
#
# Runs before the gateway starts. Expects SSH keys to already be on the
# persistent volume (or in the container) for private repo access.
#
# Environment:
#   WORKSPACE_REPO     — git SSH URL (required)
#   WORKSPACE_DIR      — clone target (default: /data/workspace)
#   OPENCLAW_AGENT_ID  — agent identity (default: main)

set -euo pipefail

WORKSPACE_REPO="${WORKSPACE_REPO:-}"
WORKSPACE_DIR="${WORKSPACE_DIR:-/data/workspace}"
AGENT_ID="${OPENCLAW_AGENT_ID:-main}"
BRANCH="agent/${AGENT_ID}"
MAIN_BRANCH="${WORKSPACE_MAIN_BRANCH:-main}"

if [ -z "${WORKSPACE_REPO}" ]; then
  echo "[workspace-boot] WORKSPACE_REPO not set, skipping workspace sync"
  exit 0
fi

# SSH key setup: link persistent volume keys into the node user's home.
# Keys are expected at /data/.ssh/ (placed there via fly ssh console or volume).
mkdir -p ~/.ssh
chmod 700 ~/.ssh

DATA_SSH="/data/.ssh"
if [ -d "${DATA_SSH}" ]; then
  for keyfile in "${DATA_SSH}"/id_*; do
    [ -f "${keyfile}" ] || continue
    base=$(basename "${keyfile}")
    cp "${keyfile}" ~/.ssh/"${base}"
    chmod 600 ~/.ssh/"${base}"
  done
  [ -f "${DATA_SSH}/config" ] && cp "${DATA_SSH}/config" ~/.ssh/config
  echo "[workspace-boot] loaded SSH keys from ${DATA_SSH}"
fi

# Trust github.com host key if not already known
if ! grep -q "github.com" ~/.ssh/known_hosts 2>/dev/null; then
  ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts 2>/dev/null || true
fi

# Clone or fetch
if [ -d "${WORKSPACE_DIR}/.git" ]; then
  echo "[workspace-boot] fetching latest for ${WORKSPACE_DIR}"
  cd "${WORKSPACE_DIR}"
  git fetch origin --quiet
elif [ -d "${WORKSPACE_DIR}" ] && [ "$(ls -A "${WORKSPACE_DIR}" 2>/dev/null)" ]; then
  # Directory exists but isn't a git repo — init and set remote
  echo "[workspace-boot] existing non-git dir at ${WORKSPACE_DIR}, initializing"
  cd "${WORKSPACE_DIR}"
  git init --quiet
  git remote add origin "${WORKSPACE_REPO}" 2>/dev/null || git remote set-url origin "${WORKSPACE_REPO}"
  git fetch origin --quiet
  git checkout -b "${MAIN_BRANCH}" "origin/${MAIN_BRANCH}" --quiet 2>/dev/null || true
else
  echo "[workspace-boot] cloning ${WORKSPACE_REPO} → ${WORKSPACE_DIR}"
  mkdir -p "$(dirname "${WORKSPACE_DIR}")"
  git clone "${WORKSPACE_REPO}" "${WORKSPACE_DIR}" --quiet
  cd "${WORKSPACE_DIR}"
fi

# Checkout or create agent branch
if git show-ref --verify --quiet "refs/heads/${BRANCH}"; then
  git checkout "${BRANCH}" --quiet
elif git show-ref --verify --quiet "refs/remotes/origin/${BRANCH}"; then
  git checkout -b "${BRANCH}" "origin/${BRANCH}" --quiet
else
  git checkout -b "${BRANCH}" "origin/${MAIN_BRANCH}" --quiet
  echo "[workspace-boot] created new branch ${BRANCH}"
fi

# Merge latest main into agent branch
if ! git merge "origin/${MAIN_BRANCH}" --no-edit --quiet 2>/dev/null; then
  echo "[workspace-boot] WARNING: merge conflict pulling main into ${BRANCH}"
  echo "[workspace-boot] agent will resolve on first sync"
  # Don't abort — let the agent handle it when it starts
fi

# Copy openclaw.json to state dir if workspace has one
if [ -f "${WORKSPACE_DIR}/openclaw.json" ]; then
  OPENCLAW_STATE="${OPENCLAW_STATE_DIR:-/data}"
  cp "${WORKSPACE_DIR}/openclaw.json" "${OPENCLAW_STATE}/openclaw.json"
  echo "[workspace-boot] synced openclaw.json → ${OPENCLAW_STATE}/openclaw.json"
fi

# Configure git identity for agent commits
git config user.name "Agent ${AGENT_ID}"
git config user.email "agent-${AGENT_ID}@openclaw.local"

echo "[workspace-boot] ready on branch ${BRANCH}"
