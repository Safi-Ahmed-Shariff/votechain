#!/bin/bash

echo "========================================="
echo "Tetragon Trigger: Shell Spawned"
echo "========================================="
echo ""

POD=$(kubectl get pods -n votechain -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "❌ No vote-service pod found"
    exit 1
fi

echo "Target pod: $POD"
echo "Executing: /bin/sh -c 'echo Security Test'"
echo ""

# Note: If Sigkill is enabled in your policy, this command will fail with exit code 137
kubectl exec -n votechain $POD -- /bin/sh -c 'echo "Unauthorized access test"' || echo "⚠️  Process was likely KILLED by Tetragon"

echo ""
echo "✅ Shell command attempted"
echo ""
echo "Check Tetragon Events:"
echo "  kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout --tail=50 | grep '\"binary\":\"/bin/sh\"'"
echo ""
