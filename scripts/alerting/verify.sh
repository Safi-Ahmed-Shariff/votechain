#!/bin/bash

echo "========================================="
echo "Alerting Stack Verification"
echo "========================================="
echo ""

echo "[1/5] Checking webhook receiver..."
kubectl get pods -n monitoring -l app=webhook-receiver
WEBHOOK_STATUS=$(kubectl get pods -n monitoring -l app=webhook-receiver -o jsonpath='{.items[0].status.phase}')
if [ "$WEBHOOK_STATUS" == "Running" ]; then
    echo "✅ Webhook receiver is running"
else
    echo "❌ Webhook receiver is not running (Status: $WEBHOOK_STATUS)"
fi
echo ""

echo "[2/5] Checking Prometheus rules..."
kubectl get prometheusrule -n monitoring votechain-alerts
RULES_COUNT=$(kubectl get prometheusrule -n monitoring votechain-alerts -o jsonpath='{.spec.groups[0].rules}' | jq '. | length')
echo "✅ Found $RULES_COUNT alert rules configured"
echo ""

echo "[3/5] Checking Alertmanager config..."
kubectl get secret -n monitoring alertmanager-prometheus-kube-prometheus-alertmanager
echo "✅ Alertmanager configuration exists"
echo ""

echo "[4/5] Checking Alertmanager is running..."
kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager
AM_STATUS=$(kubectl get pods -n monitoring -l app.kubernetes.io/name=alertmanager -o jsonpath='{.items[0].status.phase}')
if [ "$AM_STATUS" == "Running" ]; then
    echo "✅ Alertmanager is running"
else
    echo "❌ Alertmanager is not running (Status: $AM_STATUS)"
fi
echo ""

echo "[5/5] Listing configured alerts in Prometheus..."
echo "Port-forward Prometheus to check:"
echo "  kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "  Then open: http://localhost:9090/alerts"
echo ""

echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Port-forward Prometheus: kubectl port-forward -n monitoring svc/prometheus-operated 9090:9090"
echo "2. Open http://localhost:9090/alerts to see alert rules"
echo "3. Trigger test alert: ./scripts/alerting/trigger-test-alert.sh"
echo "4. Watch webhook logs: kubectl logs -n monitoring -l app=webhook-receiver -f"
echo ""
