#!/bin/bash
set -e

export VAULT_ADDR='http://127.0.0.1:8200'
export VAULT_TOKEN='root'

echo "========================================="
echo "Configuring HashiCorp Vault"
echo "========================================="
echo ""

VAULT_POD=$(kubectl get pods -n vault -l app=vault -o jsonpath='{.items[0].metadata.name}')

echo "[1/8] Enabling KV secrets engine..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault secrets enable -path=secret kv-v2" || echo "Already enabled"

echo ""
echo "[2/8] Storing sample secrets..."

# Database credentials
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/database/vote username=vote_user password=vote_pass_12345"

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/database/auth username=auth_user password=auth_pass_12345"

# JWT signing key
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/jwt/signing-key key=super_secret_jwt_key_change_in_production"

# Biometric encryption key
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/encryption/biometric-key key=aes256_encryption_key_32_bytes_long"

# API keys
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/vote/api-key key=vote_api_key_abc123"

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/auth/api-key key=auth_api_key_def456"

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv put secret/biometric/api-key key=biometric_api_key_ghi789"

echo ""
echo "[3/8] Creating Vault policies..."

kubectl exec -n vault $VAULT_POD -- sh -c 'cat > /tmp/vote-policy.hcl << EOL
path "secret/data/vote/*" {
  capabilities = ["read", "list"]
}
path "secret/data/database/vote" {
  capabilities = ["read"]
}
EOL'

kubectl exec -n vault $VAULT_POD -- sh -c 'cat > /tmp/auth-policy.hcl << EOL
path "secret/data/auth/*" {
  capabilities = ["read", "list"]
}
path "secret/data/database/auth" {
  capabilities = ["read"]
}
path "secret/data/jwt/signing-key" {
  capabilities = ["read"]
}
EOL'

kubectl exec -n vault $VAULT_POD -- sh -c 'cat > /tmp/biometric-policy.hcl << EOL
path "secret/data/biometric/*" {
  capabilities = ["read", "list"]
}
path "secret/data/encryption/biometric-key" {
  capabilities = ["read"]
}
EOL'

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault policy write vote-policy /tmp/vote-policy.hcl"
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault policy write auth-policy /tmp/auth-policy.hcl"
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault policy write biometric-policy /tmp/biometric-policy.hcl"

echo ""
echo "[4/8] Enabling Kubernetes auth method..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault auth enable kubernetes" || echo "Already enabled"

echo ""
echo "[5/8] Configuring Kubernetes auth..."

# Get Kubernetes host
K8S_HOST="https://kubernetes.default.svc:443"

# Get service account token and CA cert
SA_JWT_TOKEN=$(kubectl get secret -n vault $(kubectl get sa vault -n vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.token}' | base64 -d)
SA_CA_CRT=$(kubectl get secret -n vault $(kubectl get sa vault -n vault -o jsonpath='{.secrets[0].name}') -o jsonpath='{.data.ca\.crt}' | base64 -d)

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault write auth/kubernetes/config token_reviewer_jwt='$SA_JWT_TOKEN' kubernetes_host='$K8S_HOST' kubernetes_ca_cert='$SA_CA_CRT'"

echo ""
echo "[6/8] Creating Kubernetes auth roles..."

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault write auth/kubernetes/role/vote-role bound_service_account_names=vote-sa bound_service_account_namespaces=votechain policies=vote-policy ttl=1h"

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault write auth/kubernetes/role/auth-role bound_service_account_names=auth-sa bound_service_account_namespaces=votechain policies=auth-policy ttl=1h"

kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault write auth/kubernetes/role/biometric-role bound_service_account_names=biometric-sa bound_service_account_namespaces=votechain policies=biometric-policy ttl=1h"

echo ""
echo "[7/8] Verifying secrets storage..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv get secret/database/vote"

echo ""
echo "[8/8] Listing all secrets..."
kubectl exec -n vault $VAULT_POD -- sh -c "VAULT_TOKEN=root vault kv list secret/"

echo ""
echo "========================================="
echo "✅ Vault configuration complete"
echo "========================================="
