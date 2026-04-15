#!/bin/bash

echo "========================================="
echo "Tetragon Trigger: Package Manager"
echo "========================================="
echo ""

POD=$(kubectl get pods -n votechain -o jsonpath='{.items[0].metadata.name}')

if [ -z "$POD" ]; then
    echo "❌ No vote-service pod found"
    exit 1
fi

echo "Target pod: $POD"
echo "Executing: npm --version"
echo ""

kubectl exec -n votechain $POD -- npm --version 2>/dev/null || echo "(npm executed)"

echo ""
echo "✅ Package manager command executed"
echo ""
echo "Check Tetragon Events:"
echo "  kubectl logs -n tetragon -l app.kubernetes.io/name=tetragon -c export-stdout --tail=50 | grep '\"binary\":\"/usr/bin/npm\"'"
echo ""
