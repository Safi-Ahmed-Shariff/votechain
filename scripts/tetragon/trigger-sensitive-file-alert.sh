#!/bin/bash

echo "========================================="
echo "Tetragon Trigger: Sensitive File Access"
echo "========================================="
echo ""

POD=$(kubectl get pods -n votechain -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "❌ No vote-service pod found"
    exit 1
fi

echo "Target pod: $POD"
echo "Executing: cat /etc/passwd"
echo ""

kubectl exec -n votechain $POD -- cat /etc/passwd > /dev/null

echo ""
echo "✅ Sensitive file read"
echo ""
echo "Check Tetragon Events:"
echo "  kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout --tail=50 | grep '/etc/passwd'"
echo ""
