#!/bin/bash

echo "========================================="
echo "Triggering Test Alert (HighPodMemory)"
echo "========================================="
echo ""

echo "This script will create a memory-intensive pod that triggers the HighPodMemory alert."
echo "Alert threshold: 400Mi for 2 minutes"
echo ""

# Create a pod that allocates 500Mi of memory
cat <<YAML | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: memory-hog
  namespace: votechain
  labels:
    app: memory-test
spec:
  containers:
  - name: stress
    image: polinux/stress
    resources:
      requests:
        memory: "500Mi"
      limits:
        memory: "600Mi"
    command: ["stress"]
    args: ["--vm", "1", "--vm-bytes", "500M", "--vm-hang", "0"]
YAML

echo ""
echo "✅ Memory-intensive pod created"
echo ""
echo "What happens next:"
echo "1. Pod 'memory-hog' will consume 500Mi RAM"
echo "2. After ~2 minutes, HighPodMemory alert will fire"
echo "3. Prometheus sends alert to Alertmanager"
echo "4. Alertmanager sends webhook to receiver"
echo "5. Check webhook receiver logs:"
echo ""
echo "  kubectl logs -n monitoring -l app=webhook-receiver -f"
echo ""
echo "To clean up the test pod:"
echo "   kubectl delete pod memory-hog -n votechain"
echo ""
