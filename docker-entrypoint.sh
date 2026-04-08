#!/bin/sh
set -e

# Use environment variables if present, otherwise fallback to defaults
GIT_USER=${GIT_USER:-GastownUser}
GIT_EMAIL=${GIT_EMAIL:-gastown@example.com}

echo "Configuring identity for $GIT_USER <$GIT_EMAIL>..."
git config --global user.name "$GIT_USER"
git config --global user.email "$GIT_EMAIL"
git config --global credential.helper store
git config --global init.defaultBranch main

# Dolt config (ignore errors if already set)
dolt config --global --add user.name "$GIT_USER" 2>/dev/null || true
dolt config --global --add user.email "$GIT_EMAIL" 2>/dev/null || true

# Initialize or refresh Gas Town workspace
if [ ! -f /gt/mayor/town.json ]; then
    echo "Initializing Gas Town workspace at /gt..."
    gt install /gt --git
else
    echo "Refreshing Gas Town workspace at /gt..."
    gt install /gt --git --force
fi

exec "$@"
