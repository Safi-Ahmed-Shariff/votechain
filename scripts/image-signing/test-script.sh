#!/bin/bash
set -euo pipefail

NAMESPACE="votechain"
BAD_IMAGE="nginx:latest"
GOOD_IMAGE="ghcr.io/safi-ahmed-shariff/vote-service:latest"

clear

echo "==============================================="
echo "   KYVERNO ADMISSION CONTROL SECURITY DEMO"
echo "==============================================="
echo ""
echo "Namespace : ${NAMESPACE}"
echo "Policy    : Allow only trusted VoteChain images"
echo ""

read -p "Run demo? (yes/no): " CONFIRM
[[ "$CONFIRM" == "yes" ]] || exit 1

echo ""
echo "###############################################"
echo "# TEST 1 - Untrusted Public Image"
echo "# Attempting: ${BAD_IMAGE}"
echo "###############################################"
echo ""

BAD_OUTPUT=$(kubectl run blocked-test \
  --image=${BAD_IMAGE} \
  -n ${NAMESPACE} \
  --restart=Never 2>&1 || true)

echo "$BAD_OUTPUT"
echo ""

if echo "$BAD_OUTPUT" | grep -qiE "denied|forbidden|violation"; then
  echo "✅ SECURITY SUCCESS: Untrusted image blocked by Kyverno"
else
  echo "❌ WARNING: Pod admitted unexpectedly"
  kubectl delete pod blocked-test -n ${NAMESPACE} --force --grace-period=0 >/dev/null 2>&1 || true
fi

sleep 2

echo ""
echo "###############################################"
echo "# TEST 2 - Trusted VoteChain Image"
echo "# Attempting: ${GOOD_IMAGE}"
echo "###############################################"
echo ""

GOOD_OUTPUT=$(kubectl run allowed-test \
  --image=${GOOD_IMAGE} \
  -n ${NAMESPACE} \
  --restart=Never 2>&1 || true)

echo "$GOOD_OUTPUT"
echo ""

sleep 5

if kubectl get pod allowed-test -n ${NAMESPACE} >/dev/null 2>&1; then
  STATUS=$(kubectl get pod allowed-test -n ${NAMESPACE} -o jsonpath='{.status.phase}')
  echo "✅ SECURITY SUCCESS: Trusted image allowed"
  echo "Pod Status: ${STATUS}"
  kubectl get pod allowed-test -n ${NAMESPACE}
else
  echo "❌ Trusted image was blocked unexpectedly"
fi

echo ""
echo "Cleaning up..."
kubectl delete pod allowed-test -n ${NAMESPACE} --force --grace-period=0 >/dev/null 2>&1 || true

echo ""
echo "==============================================="
echo " Demo Complete"
echo " Kyverno enforced trusted image policy"
echo "==============================================="
