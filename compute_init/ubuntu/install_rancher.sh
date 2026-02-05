#!/bin/bash
set -euo pipefail
set -x

# ------------------------------
# Install / start RKE2 (server)
# ------------------------------
if ! systemctl list-unit-files | grep -q '^rke2-server\.service'; then
  curl -sfL https://get.rke2.io | INSTALL_RKE2_TYPE=server sh -
fi

systemctl enable rke2-server.service
systemctl start rke2-server.service

# ------------------------------
# Wait for kubeconfig to exist
# ------------------------------
for i in {1..60}; do
  [[ -f /etc/rancher/rke2/rke2.yaml ]] && break
  sleep 2
done
[[ -f /etc/rancher/rke2/rke2.yaml ]] || { echo "rke2.yaml not found"; exit 1; }

# ------------------------------
# Ensure kubectl is available (RKE2 ships one)
# Prefer RKE2 kubectl to avoid PATH issues
# ------------------------------
KUBECTL="/var/lib/rancher/rke2/bin/kubectl"
if [[ -x "$KUBECTL" ]]; then
  ln -sf "$KUBECTL" /usr/local/bin/kubectl
fi
command -v kubectl >/dev/null 2>&1 || { echo "kubectl not found in PATH"; exit 1; }

# ------------------------------
# Write ubuntu kubeconfig (no ~ ambiguity)
# ------------------------------
install -d -m 0700 -o ubuntu -g ubuntu /home/ubuntu/.kube
install -m 0600 -o ubuntu -g ubuntu /etc/rancher/rke2/rke2.yaml /home/ubuntu/.kube/config

# ------------------------------
# Configure JWKS discovery (idempotent write)
# NOTE: these settings are for internal testing only
# ------------------------------
install -d -m 0755 /etc/rancher/rke2

cat >/etc/rancher/rke2/config.yaml <<'EOF'
# For testing internal-only:
kube-apiserver-arg:
  - "service-account-issuer=https://kubernetes.default.svc"
  - "service-account-jwks-uri=https://kubernetes.default.svc/openid/v1/jwks"
EOF

systemctl restart rke2-server.service

# ------------------------------
# Wait for API to come up after restart
# ------------------------------
export KUBECONFIG=/etc/rancher/rke2/rke2.yaml

for i in {1..90}; do
  kubectl get --raw=/readyz >/dev/null 2>&1 && break
  sleep 2
done

kubectl get --raw=/readyz >/dev/null 2>&1 || { echo "API not ready"; exit 1; }

# ------------------------------
# Sanity checks
# ------------------------------
kubectl get nodes
kubectl get pods -A

kubectl get --raw /.well-known/openid-configuration || echo "no discovery"
kubectl get --raw /openid/v1/jwks || echo "no jwks"

# ------------------------------
# Install the Local Storage Provisioner
# ------------------------------
kubectl apply -f https://raw.githubusercontent.com/rancher/local-path-provisioner/v0.0.30/deploy/local-path-storage.yaml
kubectl patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
kubectl get sc
