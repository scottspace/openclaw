#!/bin/bash
# Setup Git repository with remote

set -e

if [ $# -lt 1 ]; then
    echo "Usage: $0 <remote-url> [branch]"
    echo "Example: $0 git@github.com:user/repo.git master"
    exit 1
fi

REMOTE_URL="$1"
BRANCH="${2:-master}"

# Check if we're in a git repository
if [ ! -d .git ]; then
    echo "Initializing Git repository..."
    git init
fi

# Add remote if it doesn't exist
if ! git remote | grep -q "^origin$"; then
    echo "Adding remote 'origin'..."
    git remote add origin "$REMOTE_URL"
    echo "✓ Remote added"
else
    echo "✓ Remote 'origin' already exists"
    # Update URL if different
    CURRENT_URL=$(git remote get-url origin)
    if [ "$CURRENT_URL" != "$REMOTE_URL" ]; then
        echo "Updating remote URL..."
        git remote set-url origin "$REMOTE_URL"
        echo "✓ Remote URL updated"
    fi
fi

echo ""
echo "=== REPOSITORY STATUS ==="
echo "Remote: $REMOTE_URL"
echo "Branch: $BRANCH"
echo ""
git remote -v
