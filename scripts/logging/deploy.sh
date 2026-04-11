#!/bin/bash
set -e

echo "========================================="
echo "VoteChain Day 13 — ELK Stack Deployment"
echo "========================================="
echo ""

echo "[1/5] Creating logging namespace..."
if ! kubectl get namespace logging > /dev/null 2>&1; then
    echo "Namespace 'logging' not found. Creating namespace..."
    kubectl create namespace logging
else
    echo "Namespace 'logging' already exists. Skipping creation."
fi
echo ""
echo "[2/5] Deploying Elasticsearch (this takes 2-3 minutes)..."
kubectl apply -f ~/votechain/k8s/logging/elasticsearch.yaml
echo "Waiting for Elasticsearch to be ready..."
kubectl rollout status statefulset/elasticsearch -n logging --timeout=1200s

echo ""
echo "[3/5] Deploying Kibana..."
kubectl apply -f ~/votechain/k8s/logging/kibana.yaml
echo "Waiting for Kibana to be ready..."
kubectl rollout status deployment/kibana -n logging --timeout=1200s

echo ""
echo "[4/5] Deploying Filebeat..."
kubectl apply -f ~/votechain/k8s/logging/filebeat.yaml
sleep 10

echo ""
echo "[5/5] Verifying cluster health..."
kubectl exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health?pretty

echo ""
echo "========================================="
echo "✅ ELK Stack deployed successfully"
echo "========================================="
echo ""
echo "Access points:"
echo "- Kibana UI: http://localhost:30561"
echo ""
echo "Next steps:"
echo "1. Wait 1-2 minutes for logs to be indexed"
echo "2. Open Kibana → Management → Index Patterns"
echo "3. Create index pattern: filebeat-*"
echo "4. Select time field: @timestamp"
echo "5. Go to Discover tab to view logs"
echo ""
echo "Search examples:"
echo "- kubernetes.namespace:votechain"
echo "- kubernetes.pod.name:vote-service*"
echo "- message:*error*"
echo ""
