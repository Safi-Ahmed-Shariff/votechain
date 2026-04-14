#!/bin/bash
set -e

echo "========================================="
echo "VoteChain Day 15 — HashiCorp Vault"
echo "========================================="
echo ""

echo "[1/4] Creating vault namespace..."
kubectl apply -f ~/votechain/k8s/vault/vault-namespace.yaml

echo ""
echo "[2/4] Deploying Vault server (dev mode)..."
kubectl apply -f ~/votechain/k8s/vault/vault-server.yaml
echo "Waiting for Vault to be ready (this takes 30-60 seconds)..."
kubectl wait --for=condition=ready pod -l app=vault -n vault --timeout=120s

echo ""
echo "[3/4] Creating VoteChain ServiceAccounts..."
kubectl apply -f ~/votechain/k8s/vault/vault-serviceaccounts.yaml

echo ""
echo "[4/4] Creating Vault policies ConfigMap..."
kubectl apply -f ~/votechain/k8s/vault/vault-policies.yaml

echo ""
echo "========================================="
echo "✅ Vault deployed successfully"
echo "========================================="
echo ""
echo "⚠️  IMPORTANT: Vault is running in DEV MODE"
echo "   - Secrets are NOT persisted (lost on restart)"
echo "   - Auto-unsealed (no unseal keys)"
echo "   - Root token: root"
echo "   - Not suitable for production"
echo ""
echo "Next steps:"
echo "1. Run setup script to configure Vault:"
echo "   ./scripts/vault/setup-vault.sh"
echo ""
echo "2. Verify setup:"
echo "   ./scripts/vault/verify.sh"
echo ""
echo "3. Test secret injection:"
echo "   ./scripts/vault/test-secret-injection.sh"
echo ""
echo "Access Vault UI:"
echo "   http://localhost:30820/ui"
echo "   Token: root"
echo ""

