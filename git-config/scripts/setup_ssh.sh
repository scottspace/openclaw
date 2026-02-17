#!/bin/bash
# Generate SSH key for Git authentication

set -e

COMMENT="${1:-openclaw-git}"
SSH_DIR="$HOME/.ssh"
KEY_PATH="$SSH_DIR/id_ed25519"

# Create .ssh directory if it doesn't exist
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"

# Generate SSH key if it doesn't exist
if [ ! -f "$KEY_PATH" ]; then
    echo "Generating SSH key..."
    ssh-keygen -t ed25519 -C "$COMMENT" -f "$KEY_PATH" -N ""
    echo "✓ SSH key generated"
else
    echo "✓ SSH key already exists"
fi

# Setup SSH config for GitHub
if [ ! -f "$SSH_DIR/config" ]; then
    cat > "$SSH_DIR/config" <<EOF
Host github.com
    HostName github.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes

Host gitlab.com
    HostName gitlab.com
    User git
    IdentityFile ~/.ssh/id_ed25519
    IdentitiesOnly yes
EOF
    chmod 600 "$SSH_DIR/config"
    echo "✓ SSH config created"
fi

# Add GitHub to known_hosts
if ! grep -q "github.com" "$SSH_DIR/known_hosts" 2>/dev/null; then
    ssh-keyscan github.com >> "$SSH_DIR/known_hosts" 2>/dev/null
    echo "✓ Added GitHub to known_hosts"
fi

# Output public key
echo ""
echo "=== PUBLIC KEY ==="
echo "Add this to your Git provider (GitHub/GitLab):"
echo ""
cat "$KEY_PATH.pub"
echo ""
