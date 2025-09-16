#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="${1:-$HOME/arduino-shit}"
BRANCH="${2:-main}"

if [[ ! -d "$REPO_DIR/.git" ]]; then
  echo "Repo not found: $REPO_DIR" >&2
  exit 1
fi

cd "$REPO_DIR"
echo "[$(date -Is)] Updating $REPO_DIR (branch: $BRANCH)" >> "$REPO_DIR/auto_update.log"
git fetch origin >> "$REPO_DIR/auto_update.log" 2>&1 || true
git reset --hard "origin/$BRANCH" >> "$REPO_DIR/auto_update.log" 2>&1 || true
git clean -fd >> "$REPO_DIR/auto_update.log" 2>&1 || true
echo "[$(date -Is)] Update complete" >> "$REPO_DIR/auto_update.log"


