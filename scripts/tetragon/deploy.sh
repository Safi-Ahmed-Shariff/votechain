#!/bin/bash
set -e

echo "========================================="
echo "VoteChain — Tetragon Security Deployment"
echo "========================================="
echo ""

# 1. Setup Helm Repository
echo "[1/4] Adding Cilium Helm repository..."
helm repo add cilium https://helm.cilium.io > /dev/null 2>&1
helm repo update > /dev/null 2>&1

# 2. Create Namespaces
echo "[2/4] Ensuring namespaces exist..."
kubectl create namespace tetragon --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace votechain --dry-run=client -o yaml | kubectl apply -f -

# 3. Install/Upgrade Tetragon
echo "[3/4] Installing Tetragon Agent via Helm..."
# Using upgrade --install handles both first-time setup and updates
helm upgrade --install tetragon cilium/tetragon \
  --namespace tetragon \
  --set tetragon.exportDirectory=/var/run/tetragon/ \
  --wait

# 4. Deploy VoteChain Security Policies
echo "[4/4] Applying VoteChain Tracing Policies..."
if [ -f "~/votechain/k8s/tetragon/votechain-policy.yaml" ]; then
    kubectl apply -f ~/votechain/k8s/tetragon/votechain-policy.yaml
else
    # Fallback to current directory if the absolute path fails in different environments
    kubectl apply -f ../../k8s/tetragon/votechain-policy.yaml
fi

echo ""
echo "Waiting for Tetragon to be ready..."
kubectl rollout status ds/tetragon -n tetragon --timeout=300s

echo ""
echo "========================================="
echo "✅ Tetragon deployed successfully"
echo "========================================="
echo ""
echo "🛡️  Security Policy Active: votechain-security-policy"
echo "Target Namespace: votechain"
echo ""
echo "Enforced Rules:"
echo "  • Shell Spawned in VoteChain (POST/LOG)"
echo "  • Package Manager Execution (POST/LOG)"
echo "  • Sensitive File Access (POST/LOG)"
echo "  • Network Tool Execution (POST/LOG)"
echo ""
echo "Next steps:"
echo "1. Verify Tetragon is running:"
echo "   ./scripts/tetragon/verify.sh"
echo ""
echo "2. Watch security events in real-time:"
echo "   kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout -f | jq ."
echo ""
echo "3. Test the policy (Trigger a SIGKILL/Log):"
echo "   kubectl exec -it -n votechain <pod-name> -- /bin/bash"
echo ""
