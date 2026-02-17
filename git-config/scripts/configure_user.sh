#!/bin/bash
# Configure Git user identity

set -e

if [ $# -lt 2 ]; then
    echo "Usage: $0 <name> <email>"
    echo "Example: $0 'Tensor Claw' 'clawtensor@gmail.com'"
    exit 1
fi

NAME="$1"
EMAIL="$2"

# Configure Git globally
git config --global user.name "$NAME"
git config --global user.email "$EMAIL"

echo "✓ Git user configured:"
echo "  Name:  $NAME"
echo "  Email: $EMAIL"

# Show current config
echo ""
echo "=== CURRENT GIT CONFIG ==="
git config --global --list | grep user
