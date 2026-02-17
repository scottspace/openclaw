---
name: git-config
description: Configure Git SSH keys, user identity, and repository setup for automated commits and pushes. Use when setting up Git authentication, configuring user credentials, managing SSH keys for GitHub/GitLab, or automating Git workflows.
homepage: https://git-scm.com
metadata:
  {
    "openclaw":
      {
        "emoji": "🔧",
        "requires": { "bins": ["git", "ssh-keygen"] }
      }
  }
---

# Git Config

Configure Git for automated workflows with SSH authentication and proper identity.

## Overview

This skill handles:
- SSH key generation for Git authentication
- Git user identity configuration (name/email)
- Repository remote setup
- Common Git operations (commit, push, pull)

## Setup Workflow

### 1. Generate SSH Key

```bash
scripts/setup_ssh.sh <key-comment>
```

Example:
```bash
scripts/setup_ssh.sh "openclaw-bot"
```

Returns the public key to add to GitHub/GitLab.

### 2. Configure Git Identity

```bash
scripts/configure_user.sh <name> <email>
```

Example:
```bash
scripts/configure_user.sh "Tensor Claw" "clawtensor@gmail.com"
```

### 3. Setup Repository

```bash
scripts/setup_repo.sh <remote-url> [branch]
```

Example:
```bash
scripts/setup_repo.sh git@github.com:user/repo.git master
```

## Common Operations

### Commit and Push

```bash
git add .
git commit -m "Commit message"
git push
```

### Pull Latest Changes

```bash
git pull origin <branch>
```

### Check Status

```bash
git status
git log --oneline -10
```

## Notes

- SSH keys are stored in `~/.ssh/`
- Always verify the public key before adding to Git provider
- Use descriptive commit messages
- Configure the repository remote before pushing
