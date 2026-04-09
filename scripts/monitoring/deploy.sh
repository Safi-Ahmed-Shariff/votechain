#!/bin/bash
set -e

echo "========================================="
echo "VoteChain Day 11 — Prometheus + Grafana"
echo "========================================="
echo ""

echo "[1/5] Creating monitoring namespace..."
kubectl apply -f ~/votechain/k8s/monitoring-namespace.yaml

echo ""
echo "[2/5] Adding Prometheus community Helm repo..."
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo ""
echo "[3/5] Installing kube-prometheus-stack (this takes 2-3 minutes)..."
helm upgrade --install prometheus prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --values ~/votechain/helm/votechain-chart/prometheus-values.yaml \
  --wait \
  --timeout 1000s

echo ""
echo "[4/5] Waiting for Prometheus Operator to be ready..."
kubectl rollout status deployment prometheus-kube-prometheus-operator -n monitoring --timeout=120s

echo ""
echo "[5/5] Deploying ServiceMonitors for VoteChain services..."
kubectl apply -f ~/votechain/k8s/servicemonitors/

echo ""
echo "========================================="
echo "✅ Monitoring stack deployed successfully"
echo "========================================="
echo ""
echo "Access points:"
echo "- Grafana UI: http://localhost:30900"
echo "  Username: admin"
echo "  Password: votechain-grafana-admin"
echo ""
echo "- Prometheus UI: kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "  Then open: http://localhost:9090"
echo ""
echo "- Alertmanager UI: kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093"
echo "  Then open: http://localhost:9093"
echo ""
echo "Verify metrics scraping:"
echo "kubectl get servicemonitor -n votechain"
echo ""
echo "Check Prometheus targets:"
echo "Open Prometheus UI → Status → Targets"
echo "Look for: votechain-services/votechain/*"
echo ""
