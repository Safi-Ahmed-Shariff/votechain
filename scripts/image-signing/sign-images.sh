#!/bin/bash
set -e

echo "========================================="
echo "Signing VoteChain Container Images"
echo "========================================="
echo ""

# Check if cosign.key exists
if [ ! -f ~/votechain/keys/cosign.key ]; then
    echo "❌ cosign.key not found!"
    echo "Run ./scripts/image-signing/generate-keys.sh first"
    exit 1
fi

# Your GitHub Container Registry username
read -p "Enter your GitHub username: " GITHUB_USER

if [ -z "$GITHUB_USER" ]; then
    echo "❌ GitHub username required"
    exit 1
fi

# Convert username to lowercase to satisfy Docker naming rules (Fixes the lowercase error)
GITHUB_USER=$(echo "$GITHUB_USER" | tr '[:upper:]' '[:lower:]')

# Services mapping: image_name -> directory_name
declare -A SERVICES=(
    ["vote-service"]="vote"
    ["auth-service"]="auth"
    ["biometric-service"]="biometric"
)

echo "This script will sign the following images:"
for IMAGE in "${!SERVICES[@]}"; do
    echo "  • ${IMAGE}:latest"
done
echo ""

read -p "Continue? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Aborted."
    exit 1
fi

echo ""
echo "You will be prompted for your cosign.key password for each image."
echo ""

cd ~/votechain/keys

for IMAGE in "${!SERVICES[@]}"; do
    SERVICE_DIR="${SERVICES[$IMAGE]}"
    
    echo "========================================="
    echo "Processing: ${IMAGE}:latest"
    echo "========================================="
    
    # Check if image exists locally
    if ! docker image inspect ${IMAGE}:latest > /dev/null 2>&1; then
        echo "⚠️  Image ${IMAGE}:latest not found locally"
        echo "Building image from services/${SERVICE_DIR}..."
        
        if [ ! -d ~/votechain/services/${SERVICE_DIR} ]; then
            echo "❌ Directory ~/votechain/services/${SERVICE_DIR} not found!"
            echo "Skipping ${IMAGE}..."
            echo ""
            continue
        fi
        
        cd ~/votechain/services/${SERVICE_DIR}
        docker build -t ${IMAGE}:latest .
        cd ~/votechain/keys
    else
        echo "✅ Image ${IMAGE}:latest found locally"
    fi
    
    # --- UPDATED SECTION FOR GHCR SIGNING ---
    echo "Preparing ${IMAGE}:latest for GHCR..."
    
    # 1. Tag the image for GHCR
    docker tag ${IMAGE}:latest ghcr.io/${GITHUB_USER}/${IMAGE}:latest

    # 2. Push the image
    echo "Pushing ghcr.io/${GITHUB_USER}/${IMAGE}:latest..."
    docker push ghcr.io/${GITHUB_USER}/${IMAGE}:latest

    # 3. Sign the GHCR version
    echo "Signing ghcr.io/${GITHUB_USER}/${IMAGE}:latest..."
    cosign sign --key cosign.key ghcr.io/${GITHUB_USER}/${IMAGE}:latest
    # ----------------------------------------
    
    echo "✅ Signed and Pushed: ghcr.io/${GITHUB_USER}/${IMAGE}:latest"
    echo ""
done

echo "========================================="
echo "✅ All images signed and pushed successfully"
echo "========================================="
echo ""
