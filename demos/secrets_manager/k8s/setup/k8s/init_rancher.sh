#!/bin/bash
set -euo pipefail

# For POCs use Rancher Public Key

# JWKS retrieval needs token auth:
# v1.24+ style token
# TOKEN=$(kubectl create token default) && curl -sk -H "Authorization: Bearer $TOKEN" https://kubernetes.default.svc:6443/openid/v1/jwks | jq .
# In prod a https service might be used with below to publicly expose jwks
# curl -s https://127.0.0.1/openid/v1/jwks

# Checks verify JWKS:
kubectl get --raw "https://localhost:6443/openid/v1/jwks" --insecure-skip-tls-verify | jq .
kubectl get --raw /.well-known/openid-configuration || echo "no discovery"
kubectl get --raw /openid/v1/jwks || echo "no jwks"

# Escape JSON for .env (quotes + newlines)
escaped_keys=$(kubectl get --raw /openid/v1/jwks | jq -c .)

vars_file="$demo_path/setup/vars.env"

# Replace placeholder or existing value
sed -i.bak "s|^K8S_PUBLIC_KEY=.*|K8S_PUBLIC_KEY=\"$escaped_keys\"|" "$VARS_FILE"
