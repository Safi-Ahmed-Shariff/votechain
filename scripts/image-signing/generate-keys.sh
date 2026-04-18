#!/bin/bash
set -e

echo "========================================="
echo "Generating Cosign Key Pair"
echo "========================================="
echo ""

cd ~/votechain/keys

if [ -f "cosign.key" ]; then
    echo "⚠️  cosign.key already exists!"
    echo ""
    read -p "Overwrite existing key? (yes/no): " CONFIRM
    if [ "$CONFIRM" != "yes" ]; then
        echo "Aborted."
        exit 1
    fi
fi

echo "Generating key pair..."
echo ""
echo "You will be prompted to enter a password to encrypt the private key."
echo "REMEMBER THIS PASSWORD - you'll need it to sign images."
echo ""

cosign generate-key-pair

echo ""
echo "========================================="
echo "✅ Key pair generated"
echo "========================================="
echo ""
echo "Files created:"
echo "  • cosign.key (PRIVATE KEY - never commit!)"
echo "  • cosign.pub (PUBLIC KEY - safe to commit)"
echo ""
echo "IMPORTANT:"
echo "  1. Keep cosign.key secret and secure"
echo "  2. Backup cosign.key to a secure location"
echo "  3. Remember the password you just entered"
echo "  4. cosign.key is in .gitignore (won't be committed)"
echo "  5. cosign.pub will be committed (used for verification)"
echo ""
