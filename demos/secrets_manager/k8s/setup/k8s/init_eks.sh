#!/bin/bash
set -euo pipefail

# Setup IAM EKS Admin creds
eks_name="$EKS_NAME"
eks_region="$EKS_REGION"
aws configure

# Setup kubconfig
aws eks update-kubeconfig --region "$eks_region" --name "$eks_name"
