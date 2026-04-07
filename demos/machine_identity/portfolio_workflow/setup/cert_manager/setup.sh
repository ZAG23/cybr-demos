#!/bin/bash
set -euo pipefail

source "$CYBR_DEMOS_PATH/demos/utility/ubuntu/identity_functions.sh"

printf "\n[INFO] cert-manager: Checking prerequisites\n"

if ! command -v kubectl >/dev/null 2>&1; then
  printf "[ERROR] cert-manager: kubectl is required but not installed\n"
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  printf "[ERROR] cert-manager: helm is required but not installed\n"
  exit 1
fi

if ! kubectl cluster-info >/dev/null 2>&1; then
  printf "[WARN] cert-manager: No Kubernetes cluster available — skipping\n"
  printf "[INFO] cert-manager: Connect to a cluster and re-run setup\n"
  exit 0
fi

MANIFESTS_DIR="$CYBR_DEMOS_PATH/demos/machine_identity/portfolio_workflow/setup/cert_manager/manifests"

# Stage 1: Install cert-manager
printf "\n[INFO] cert-manager: Installing cert-manager via Helm\n"
helm install cert-manager oci://quay.io/jetstack/charts/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.19.2 \
  --set crds.enabled=true \
  --wait 2>/dev/null || printf "[INFO] cert-manager: Already installed (continuing)\n"

printf "[INFO] cert-manager: Waiting for cert-manager pods\n"
kubectl wait --for=condition=Ready pods --all -n cert-manager --timeout=120s

# Stage 2: Create credential secret
if [ -n "${VCERT_API_KEY:-}" ]; then
  printf "[INFO] cert-manager: Creating SaaS API key secret\n"
  kubectl create secret generic cyberark-api-key \
    --namespace="$CM_NAMESPACE" \
    --from-literal=apikey="$VCERT_API_KEY" \
    --dry-run=client -o yaml | kubectl apply -f -

elif [ -n "${VCERT_TPP_ACCESS_TOKEN:-}" ]; then
  printf "[INFO] cert-manager: Creating Self-Hosted access-token secret\n"
  kubectl create secret generic cyberark-tpp-secret \
    --namespace="$CM_NAMESPACE" \
    --from-literal=access-token="$VCERT_TPP_ACCESS_TOKEN" \
    --dry-run=client -o yaml | kubectl apply -f -

elif [ -n "${VCERT_TPP_USER:-}" ] && [ -n "${VCERT_TPP_PASSWORD:-}" ]; then
  printf "[INFO] cert-manager: Creating Self-Hosted username/password secret\n"
  kubectl create secret generic cyberark-tpp-secret \
    --namespace="$CM_NAMESPACE" \
    --from-literal=username="$VCERT_TPP_USER" \
    --from-literal=password="$VCERT_TPP_PASSWORD" \
    --dry-run=client -o yaml | kubectl apply -f -

else
  printf "[WARN] cert-manager: No CyberArk credentials set — deploying self-signed issuer for demo\n"
  printf "[INFO] cert-manager: Set VCERT_API_KEY (SaaS) or VCERT_TPP_* (Self-Hosted) for production issuer\n"
fi

# Stage 3: Create namespace
kubectl create namespace "$CM_NAMESPACE" --dry-run=client -o yaml | kubectl apply -f -

# Stage 4: Deploy Issuer
printf "\n[INFO] cert-manager: Deploying Issuer in namespace '%s'\n" "$CM_NAMESPACE"

if [ -n "${VCERT_API_KEY:-}" ]; then
  # CyberArk Certificate Manager SaaS
  cat "$MANIFESTS_DIR/issuer-saas.yaml" \
    | sed "s|{{NAMESPACE}}|$CM_NAMESPACE|g" \
    | sed "s|{{VCERT_ZONE}}|$VCERT_ZONE|g" \
    | kubectl apply -f -

elif [ -n "${VCERT_TPP_URL:-}" ]; then
  # CyberArk Certificate Manager Self-Hosted
  cat "$MANIFESTS_DIR/issuer-tpp.yaml" \
    | sed "s|{{NAMESPACE}}|$CM_NAMESPACE|g" \
    | sed "s|{{VCERT_ZONE}}|$VCERT_ZONE|g" \
    | sed "s|{{VCERT_TPP_URL}}|$VCERT_TPP_URL|g" \
    | kubectl apply -f -

else
  # Self-signed fallback for demo
  cat "$MANIFESTS_DIR/issuer-selfsigned.yaml" \
    | sed "s|{{NAMESPACE}}|$CM_NAMESPACE|g" \
    | kubectl apply -f -
fi

# Stage 5: Request a Certificate
printf "[INFO] cert-manager: Requesting demo certificate\n"
cat "$MANIFESTS_DIR/certificate.yaml" \
  | sed "s|{{NAMESPACE}}|$CM_NAMESPACE|g" \
  | sed "s|{{COMMON_NAME}}|$CM_CERT_COMMON_NAME|g" \
  | sed "s|{{SECRET_NAME}}|$CM_CERT_SECRET_NAME|g" \
  | kubectl apply -f -

printf "[INFO] cert-manager: Waiting for certificate to be issued\n"
kubectl wait --for=condition=Ready certificate/"$USECASE_ID-cert" \
  --namespace="$CM_NAMESPACE" --timeout=120s 2>/dev/null \
  || printf "[WARN] cert-manager: Certificate not yet ready (may require CyberArk approval)\n"

printf "[INFO] cert-manager: Setup complete\n"
