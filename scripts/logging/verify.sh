#!/bin/bash

echo "========================================="
echo "ELK Stack Verification"
echo "========================================="
echo ""

echo "[1/4] Checking pods in logging namespace..."
kubectl get pods -n logging
echo ""

echo "[2/4] Checking Elasticsearch cluster health..."
kubectl exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cluster/health | grep -o '"status":"[^"]*"'
echo ""

echo "[3/4] Checking if indices are created..."
kubectl exec -n logging elasticsearch-0 -- curl -s http://localhost:9200/_cat/indices?v
echo ""

echo "[4/4] Checking Filebeat logs for errors..."
kubectl logs -n logging -l app=filebeat --tail=10 | grep -i error || echo "No errors in Filebeat logs"
echo ""

echo "========================================="
echo "Verification Complete"
echo "========================================="
echo ""
echo "Access Kibana: http://localhost:30561"
echo ""
