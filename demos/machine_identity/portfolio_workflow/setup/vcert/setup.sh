#!/bin/bash
set -euo pipefail

printf "\n[INFO] VCert: Checking Python prerequisites\n"

if ! command -v python3 >/dev/null 2>&1; then
  printf "[ERROR] VCert: python3 is required but not installed\n"
  exit 1
fi

if ! python3 -c "import vcert" 2>/dev/null; then
  printf "[INFO] VCert: Installing vcert Python SDK\n"
  pip3 install --quiet vcert
fi

printf "[INFO] VCert: SDK ready\n"

if [ -z "${VCERT_API_KEY:-}" ] && [ -z "${VCERT_TPP_URL:-}" ]; then
  printf "[WARN] VCert: No VCERT_API_KEY (SaaS) or VCERT_TPP_URL (Self-Hosted) configured in vars.env\n"
  printf "[INFO] VCert: Demo will run in --fake mode for illustration\n"
fi

printf "[INFO] VCert: Setup complete\n"
