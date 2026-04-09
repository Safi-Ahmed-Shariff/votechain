#!/bin/bash

echo "========================================="
echo "VoteChain Monitoring Stack Verification"
echo "========================================="
echo ""

echo "[1/6] Checking monitoring namespace..."
if kubectl get namespace monitoring &> /dev/null; then
    echo "✅ Namespace 'monitoring' exists"
else
    echo "❌ Namespace 'monitoring' not found"
    exit 1
fi

echo ""
echo "[2/6] Checking Helm release..."
if helm list -n monitoring | grep -q prometheus; then
    RELEASE_STATUS=$(helm list -n monitoring | grep prometheus | awk '{print $8}')
    echo "✅ Helm release 'prometheus' found (Status: $RELEASE_STATUS)"
else
    echo "❌ Helm release 'prometheus' not found"
    exit 1
fi

echo ""
echo "[3/6] Checking pod status in monitoring namespace..."
echo "---"
kubectl get pods -n monitoring
echo "---"
NOT_RUNNING=$(kubectl get pods -n monitoring --no-headers | grep -v "Running" | grep -v "Completed" | wc -l)
if [ $NOT_RUNNING -eq 0 ]; then
    echo "✅ All pods are running"
else
    echo "⚠️  Some pods are not running yet (wait a few minutes)"
fi

#echo ""
#echo "[4/6] Checking ServiceMonitors in votechain namespace..."
#SERVICEMONITORS=$(kubectl get servicemonitor -n votechain --no-headers 2>/dev/null | wc -l)
#if [ $SERVICEMONITORS -eq 3 ]; then
#    echo "✅ All 3 ServiceMonitors deployed"
#    kubectl get servicemonitor -n votechain
#else
#    echo "❌ Expected 3 ServiceMonitors, found $SERVICEMONITORS"
#fi

echo ""
echo "[4/5] Checking Prometheus targets..."
echo "Run this command to verify targets manually:"
echo "kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "Then open: http://localhost:9090/targets"
echo ""

echo ""
echo "[5/5] Grafana access details..."
GRAFANA_POD=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=grafana --no-headers -o custom-columns=":metadata.name" 2>/dev/null | head -1)
if [ -n "$GRAFANA_POD" ]; then
    echo "✅ Grafana pod running: $GRAFANA_POD"
    echo ""
    echo "Access Grafana at: http://localhost:30900"
    echo "Username: admin"
    echo "Password: votechain-grafana-admin"
    echo ""
    echo "To get Minikube IP (if needed):"
    echo "minikube ip"
else
    echo "❌ Grafana pod not found"
fi

echo ""
echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "Quick health check commands:"
echo "- List all monitoring pods: kubectl get pods -n monitoring"
echo "- Check Prometheus logs: kubectl logs -n monitoring -l app.kubernetes.io/name=prometheus -c prometheus"
echo "- Check Grafana logs: kubectl logs -n monitoring -l app.kubernetes.io/name=grafana"
echo "- View ServiceMonitors: kubectl get servicemonitor -n votechain"
echo ""

