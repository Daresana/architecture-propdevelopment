#!/usr/bin/env bash
set -euo pipefail
umask 077

CONTEXT=propdevelopment-sprint5
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="${CREDENTIALS_DIR:-$SCRIPT_DIR/../../.propdevelopment-users}"

if [[ -e "$OUT" ]]; then
    echo "Каталог $OUT уже существует. Для нового выпуска укажите другой CREDENTIALS_DIR." >&2
    exit 1
fi
mkdir -p "$OUT"

SERVER="$(kubectl --context "$CONTEXT" config view --minify -o jsonpath='{.clusters[0].cluster.server}')"
kubectl --context "$CONTEXT" config view --minify --flatten --raw \
    -o jsonpath='{.clusters[0].cluster.certificate-authority-data}' | openssl base64 -d -A > "$OUT/ca.crt"

# CN задаёт пользователя, O задаёт группу.
while read -r user group namespace; do
    MSYS_NO_PATHCONV=1 openssl req -new -newkey rsa:2048 -nodes \
        -keyout "$OUT/$user.key" -out "$OUT/$user.csr" \
        -subj "/CN=$user/O=$group"
    REQUEST="$(openssl base64 -A -in "$OUT/$user.csr")"
    kubectl --context "$CONTEXT" apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: $CONTEXT-$user
spec:
  request: $REQUEST
  signerName: kubernetes.io/kube-apiserver-client
  expirationSeconds: 86400
  usages:
    - client auth
EOF
    kubectl --context "$CONTEXT" certificate approve "$CONTEXT-$user"
    kubectl --context "$CONTEXT" wait --for=jsonpath='{.status.certificate}' \
        "csr/$CONTEXT-$user" --timeout=30s
    kubectl --context "$CONTEXT" get csr "$CONTEXT-$user" \
        -o jsonpath='{.status.certificate}' | openssl base64 -d -A > "$OUT/$user.crt"

    # Каждый пользователь получает отдельный kubeconfig.
    kubectl --kubeconfig "$OUT/$user.config" config set-cluster "$CONTEXT" \
        --server="$SERVER" --certificate-authority="$OUT/ca.crt" --embed-certs=true
    kubectl --kubeconfig "$OUT/$user.config" config set-credentials "$user" \
        --client-certificate="$OUT/$user.crt" --client-key="$OUT/$user.key" --embed-certs=true
    kubectl --kubeconfig "$OUT/$user.config" config set-context "$user" \
        --cluster="$CONTEXT" --user="$user" --namespace="$namespace"
    kubectl --kubeconfig "$OUT/$user.config" config use-context "$user"
done <<'EOF'
sales-manager sales-readers sales
housing-manager housing-readers housing
platform-engineer cluster-configurators housing
security-specialist security-readers housing
EOF

echo "Файлы пользователей сохранены: $OUT"
