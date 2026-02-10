#!/bin/bash
set -euo pipefail

if command -v helm >/dev/null 2>&1; then
  echo "Helm already installed: $(helm version --short)"
  exit 0
fi

echo "Installing Helm..."
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

helm version --short
