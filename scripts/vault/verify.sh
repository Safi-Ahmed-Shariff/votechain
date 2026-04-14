#!/bin/bash

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo "========================================="
echo "Vault Verification"
echo "========================================="
echo ""

VAULT_POD=$(kubectl get pods -n vault -l app=vault -o jsonpath='{.items[0].metadata.name}')

echo "[1/6] Checking Vault pod status..."
kubectl get pods -n vault -l app=vault
echo ""

echo "[2/6] Checking Vault health..."
kubectl exec -n vault $VAULT_POD -- vault status
echo ""

echo "[3/6] Listing secrets engines..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault secrets list"
echo ""

echo "[4/6] Listing auth methods..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault auth list"
echo ""

echo "[5/6] Listing policies..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault policy list"
echo ""

echo "[6/6] Testing secret read..."
echo "Reading secret/database/vote:"
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv get secret/database/vote"
echo ""

echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "Access Vault UI:"
echo "  URL: http://localhost:30820/ui"
echo "  Token: root"
echo ""
echo "Test secret injection:"
echo "  ./scripts/vault/test-secret-injection.sh"
echo ""
