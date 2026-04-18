#!/bin/bash
set -e

echo "========================================="
echo "Verifying Image Signatures on GHCR"
echo "========================================="
echo ""

# Check if cosign.pub exists
if [ ! -f ~/votechain/keys/cosign.pub ]; then
    echo "❌ cosign.pub not found!"
    exit 1
fi

# Your GitHub Container Registry username
read -p "Enter your GitHub username: " GITHUB_USER
# Convert to lowercase to match the registry path
GITHUB_USER=$(echo "$GITHUB_USER" | tr '[:upper:]' '[:lower:]')

# Images to verify (the base names)
IMAGES=(
    "vote-service"
    "auth-service"
    "biometric-service"
)

cd ~/votechain/keys

for IMAGE in "${IMAGES[@]}"; do
    # Construct the full GHCR path
    FULL_IMAGE_PATH="ghcr.io/${GITHUB_USER}/${IMAGE}:latest"

    echo "========================================="
    echo "Verifying: $FULL_IMAGE_PATH"
    echo "========================================="
    
    # We use --allow-http-registry if not using SSL, but GHCR uses SSL so this is standard:
    if cosign verify --key cosign.pub "$FULL_IMAGE_PATH"; then
        echo "✅ Valid signature found on GHCR"
    else
        echo "❌ No valid signature found for $FULL_IMAGE_PATH"
    fi
    echo ""
done

echo "========================================="
echo "Verification Complete"
echo "========================================="
