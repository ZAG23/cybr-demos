#!/usr/bin/env bash
set -euo pipefail

namespace="hashi-vault"   # use DNS-safe name (dash, not underscore)
name="vault"

kubectl get ns "$namespace" >/dev/null 2>&1 || kubectl create ns "$namespace"

cat <<'YAML' | kubectl -n "$namespace" apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vault
  labels:
    app: vault
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vault
  template:
    metadata:
      labels:
        app: vault
    spec:
      containers:
        - name: vault
          image: hashicorp/vault:1.17
          args: ["server", "-dev", "-dev-root-token-id=root"]
          env:
            - name: VAULT_ADDR
              value: "http://127.0.0.1:8200"
          ports:
            - name: http
              containerPort: 8200
---
apiVersion: v1
kind: Service
metadata:
  name: vault
  labels:
    app: vault
spec:
  selector:
    app: vault
  ports:
    - name: http
      port: 8200
      targetPort: 8200
YAML

kubectl -n "$namespace" rollout status deploy/"$name"

kubectl -n hashi-vault get pods -l app=vault -o wide
#kubectl -n hashi-vault port-forward svc/vault 8200:8200
kubectl -n hashi-vault port-forward svc/vault 8200:8200 >/tmp/vault-pf.log 2>&1 &



echo
echo "Port-forward:"
echo "  kubectl -n $namespace port-forward svc/vault 8200:8200"
echo
echo "Test:"
echo "  export VAULT_ADDR=http://127.0.0.1:8200"
echo "  export VAULT_TOKEN=root"
echo "  vault status"
