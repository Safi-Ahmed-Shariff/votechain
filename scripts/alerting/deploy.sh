#!/bin/bash
set -e

echo "========================================="
echo "VoteChain Day 14 — Alertmanager Setup"
echo "========================================="
echo ""

echo "[1/5] Deploying webhook receiver..."
kubectl apply -f ~/votechain/k8s/alerting/webhook-receiver.yaml
echo "Waiting for webhook receiver to be ready..."
kubectl wait --for=condition=ready pod -l app=webhook-receiver -n monitoring --timeout=1200s

echo ""
echo "[2/5] Creating Prometheus alert rules..."
kubectl apply -f ~/votechain/k8s/alerting/prometheus-rules.yaml

echo ""
echo "[3/5] Configuring Alertmanager..."
kubectl apply -f ~/votechain/k8s/alerting/alertmanager-config.yaml

echo ""
echo "[4/5] Restarting Alertmanager to pick up new config..."
kubectl rollout restart statefulset -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager

echo ""
echo "[5/5] Waiting for Alertmanager to be ready..."
kubectl wait --for=condition=ready pod -l app.kubernetes.io/name=alertmanager -n monitoring --timeout=1200s

echo ""
echo "========================================="
echo "✅ Alerting stack deployed successfully"
echo "========================================="
echo ""
echo "Verify setup:"
echo "1. Check Prometheus rules:"
echo "   kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "   Open: http://localhost:9090/alerts"
echo ""
echo "2. Check Alertmanager:"
echo "   kubectl port-forward -n monitoring svc/alertmanager-operated 9093:9093"
echo "   Open: http://localhost:9093"
echo ""
echo "3. Watch webhook receiver logs for incoming alerts:"
echo "   kubectl logs -n monitoring -l app=webhook-receiver -f"
echo ""
echo "4. Trigger a test alert:"
echo "   ./scripts/alerting/trigger-test-alert.sh"
echo ""
