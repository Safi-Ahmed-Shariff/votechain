#!/bin/bash

echo "========================================="
echo "Tetragon Security Verification"
echo "========================================="
echo ""

echo "[1/4] Checking Tetragon DaemonSet..."
kubectl get daemonset -n tetragon
echo ""

echo "[2/4] Checking Tetragon pods..."
kubectl get pods -n tetragon -l app.kubernetes.io/name=tetragon
echo ""

echo "[3/4] Checking VoteChain Tracing Policies..."
# Checks for the Namespaced policy we created for the votechain namespace
kubectl get tracingpolicynamespaced -n votechain votechain-security-policy
POLICY_RULES=$(kubectl get tracingpolicynamespaced -n votechain votechain-security-policy -o jsonpath='{.spec.kprobes}' | grep -c "call")
echo "✅ Found $POLICY_RULES active security hooks for VoteChain"
echo ""

echo "[4/4] Checking Tetragon event stream..."
echo "Checking last 10 lines of security events (JSON):"
echo "---"
# Tetragon uses a specific container 'export-stdout' for the JSON logs
kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout --tail=10 || echo "No events in stream yet."
echo "---"
echo ""

echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "To watch security events in real-time (Human Readable):"
echo "  kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout -f | jq ."
echo ""
echo "To filter events specifically for VoteChain pods:"
echo "  kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout -f | grep '\"namespace\":\"votechain\"'"
echo ""
echo "To trigger test events (Testing Detection/Enforcement):"
echo "  ./scripts/tetragon/trigger-shell-alert.sh"
echo "  ./scripts/tetragon/trigger-package-alert.sh"
echo ""
echo "🛡️  Note: If Sigkill is enabled in the policy, test commands will terminate immediately."
