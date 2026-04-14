#!/bin/bash
set -e

echo "========================================="
echo "Testing Vault Secret Injection"
echo "========================================="
echo ""

echo "This script creates a test pod that authenticates to Vault and reads a secret."
echo ""

# Create test pod with vote-sa ServiceAccount
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: vault-test
  namespace: votechain
spec:
  serviceAccountName: vote-sa
  containers:
  - name: vault-client
    image: hashicorp/vault:1.17.1
    command:
      - sh
      - -c
      - |
        echo "========================================="
        echo "Vault Secret Injection Test"
        echo "========================================="
        echo ""
        
        export VAULT_ADDR='http://vault.vault.svc.cluster.local:8200'
        
        echo "[1/3] Reading Kubernetes ServiceAccount token..."
        JWT=\$(cat /var/run/secrets/kubernetes.io/serviceaccount/token)
        echo "✅ Token loaded (first 20 chars): \${JWT:0:20}..."
        echo ""
        
        echo "[2/3] Authenticating to Vault using Kubernetes auth..."
        VAULT_TOKEN=\$(vault write -field=token auth/kubernetes/login \
          role=vote-role \
          jwt=\$JWT)
        
        if [ -z "\$VAULT_TOKEN" ]; then
          echo "❌ Authentication failed!"
          exit 1
        fi
        
        echo "✅ Authenticated successfully"
        echo "Vault token (first 20 chars): \${VAULT_TOKEN:0:20}..."
        echo ""
        
        export VAULT_TOKEN
        
        echo "[3/3] Reading secret from Vault..."
        echo ""
        vault kv get secret/database/vote
        echo ""
        
        echo "========================================="
        echo "✅ Secret injection test successful!"
        echo "========================================="
        echo ""
        echo "The pod successfully:"
        echo "  1. Used its Kubernetes ServiceAccount token"
        echo "  2. Authenticated to Vault as 'vote-role'"
        echo "  3. Read database credentials from Vault"
        echo ""
        
        # Keep pod running for manual inspection
        echo "Pod will remain running for manual inspection."
        echo "To view logs: kubectl logs -n votechain vault-test"
        echo "To delete pod: kubectl delete pod vault-test -n votechain"
        echo ""
        tail -f /dev/null
  restartPolicy: Never
YAML

echo ""
echo "✅ Test pod created"
echo ""
echo "Waiting for pod to start..."
kubectl wait --for=condition=ready pod/vault-test -n votechain --timeout=60s

echo ""
echo "Viewing pod logs (showing authentication and secret read)..."
echo ""
sleep 5
kubectl logs -n votechain vault-test

echo ""
echo "========================================="
echo "Test Complete"
echo "========================================="
echo ""
echo "To view logs again:"
echo "  kubectl logs -n votechain vault-test"
echo ""
echo "To clean up test pod:"
echo "  kubectl delete pod vault-test -n votechain"
echo ""
