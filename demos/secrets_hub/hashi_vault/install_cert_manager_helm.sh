# Add the Jetstack Helm repository
helm repo add jetstack https://charts.jetstack.io
helm repo update

# Install cert-manager
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.15.0 \
  --set crds.enabled=true

kubectl apply -f cert_manager_manifest.yaml
sleep 30
kubectl get secret vault-server-tls -n hashi-vault