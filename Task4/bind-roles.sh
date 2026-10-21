#!/usr/bin/env bash
set -euo pipefail

CONTEXT=propdevelopment-sprint5

for namespace in sales housing finance data; do
    kubectl --context "$CONTEXT" -n "$namespace" create rolebinding domain-readers \
        --role=domain-reader --group="$namespace-readers" --dry-run=client -o yaml |
        kubectl --context "$CONTEXT" apply -f -
    kubectl --context "$CONTEXT" -n "$namespace" create rolebinding security-readers \
        --role=secret-reader --group=security-readers --dry-run=client -o yaml |
        kubectl --context "$CONTEXT" apply -f -
done

kubectl --context "$CONTEXT" create clusterrolebinding cluster-configurators \
    --clusterrole=cluster-configurator --group=cluster-configurators \
    --dry-run=client -o yaml | kubectl --context "$CONTEXT" apply -f -
