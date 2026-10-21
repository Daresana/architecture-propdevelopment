#!/usr/bin/env bash
set -euo pipefail

CONTEXT=propdevelopment-sprint5

for namespace in sales housing finance data; do
    kubectl --context "$CONTEXT" create namespace "$namespace" --dry-run=client -o yaml |
        kubectl --context "$CONTEXT" apply -f -
    kubectl --context "$CONTEXT" -n "$namespace" create role domain-reader \
        --verb=get,list,watch \
        --resource=pods,services,events,deployments.apps,replicasets.apps,jobs.batch,cronjobs.batch \
        --dry-run=client -o yaml | kubectl --context "$CONTEXT" apply -f -
    kubectl --context "$CONTEXT" -n "$namespace" create role secret-reader \
        --verb=get,list --resource=secrets --dry-run=client -o yaml |
        kubectl --context "$CONTEXT" apply -f -
done

# Настройка инфраструктуры отделена от чтения секретов.
kubectl --context "$CONTEXT" apply -f - <<'EOF'
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: cluster-configurator
rules:
  - apiGroups: [""]
    resources: ["nodes"]
    verbs: ["get", "list", "watch", "patch", "update"]
  - apiGroups: [""]
    resources: ["namespaces"]
    verbs: ["get", "list", "watch", "create", "patch", "update"]
  - apiGroups: ["networking.k8s.io"]
    resources: ["networkpolicies"]
    verbs: ["get", "list", "watch", "create", "update", "patch", "delete"]
EOF
