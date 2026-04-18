#!/bin/bash
set -e

echo "========================================="
echo "Installing Cosign"
echo "========================================="
echo ""

COSIGN_VERSION="v2.2.3"
ARCH="amd64"

echo "Downloading Cosign ${COSIGN_VERSION}..."
wget -q "https://github.com/sigstore/cosign/releases/download/${COSIGN_VERSION}/cosign-linux-${ARCH}" -O /tmp/cosign

echo "Installing to /usr/local/bin/cosign..."
sudo install /tmp/cosign /usr/local/bin/cosign
rm /tmp/cosign

echo "Verifying installation..."
cosign version

echo ""
echo "========================================="
echo "✅ Cosign installed successfully"
echo "========================================="
echo ""
