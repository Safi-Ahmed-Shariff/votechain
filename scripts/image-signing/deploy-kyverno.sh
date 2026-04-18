#!/bin/bash
set -e

echo "========================================="
echo "VoteChain Day 17 — Kyverno Deployment"
echo "========================================="
echo ""

echo "[1/5] Creating kyverno namespace..."
kubectl apply -f ~/votechain/k8s/kyverno/kyverno-namespace.yaml

echo ""
echo "[2/5] Installing Kyverno using Helm..."
helm repo add kyverno https://kyverno.github.io/kyverno/ 2>/dev/null || true
helm repo update

helm upgrade --install kyverno kyverno/kyverno \
  --namespace kyverno \
  --create-namespace \
  --set replicaCount=1 \
  --set image.pullPolicy=IfNotPresent \
  --wait \
  --timeout=2m

echo ""
echo "[3/5] Waiting for Kyverno pods to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=kyverno -n kyverno --timeout=300s

echo ""
echo "[4/5] Checking for cosign.pub..."
if [ ! -f ~/votechain/keys/cosign.pub ]; then
    echo "⚠️  cosign.pub not found!"
    echo ""
    echo "You need to:"
    echo "  1. Run: ./scripts/image-signing/generate-keys.sh"
    echo "  2. Update k8s/kyverno/kyverno-policies.yaml with the public key"
    echo "  3. Apply policies: kubectl apply -f k8s/kyverno/kyverno-policies.yaml"
    echo ""
    echo "Kyverno is installed but policies are NOT applied yet."
else
    echo "✅ cosign.pub found"
    echo ""
    echo "[5/5] Applying Kyverno policies..."
    echo ""
    echo "⚠️  NOTE: You must update kyverno-policies.yaml with your public key first!"
    echo ""
    read -p "Have you updated the policies with your public key? (yes/no): " CONFIRM
    if [ "$CONFIRM" == "yes" ]; then
        kubectl apply -f ~/votechain/k8s/kyverno/kyverno-policies.yaml
        echo "✅ Policies applied"
    else
        echo "Skipping policy application. Apply manually after updating:"
        echo "  kubectl apply -f k8s/kyverno/kyverno-policies.yaml"
    fi
fi

echo ""
echo "========================================="
echo "✅ Kyverno deployed successfully"
echo "========================================="
echo ""
echo "Kyverno is now monitoring image signatures in the votechain namespace."
echo ""
echo "Next steps:"
echo "  1. Generate keys: ./scripts/image-signing/generate-keys.sh"
echo "  2. Update kyverno-policies.yaml with your public key"
echo "  3. Apply policies: kubectl apply -f k8s/kyverno/kyverno-policies.yaml"
echo "  4. Sign images: ./scripts/image-signing/sign-images.sh"
echo "  5. Test admission: ./scripts/image-signing/test-admission.sh"
echo ""
