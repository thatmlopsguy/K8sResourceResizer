#!/usr/bin/env bash
#
# This installation script sets up the necessary tools (kind, kubectl, and Argo CD CLI) for the Kubernetes Resource Resizer project.
# It includes error handling and verification steps to ensure a smooth installation process.

set -eu

# Default versions for the tools
KIND_VERSION="v0.31.0"
KUBECTL_VERSION="v1.34.2"
ARGOCD_VERSION="v3.3.3"

# Install kind
echo "🚀 === Installing kind ==="
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v${KIND_VERSION#v}/kind-linux-amd64
chmod +x ./kind
mv ./kind /usr/local/bin/

# Install kubectl using stable version
echo "🛠️ === Installing kubectl ==="
curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl" \
    && chmod +x kubectl \
    && mv kubectl /usr/local/bin/

# Install Argo CD CLI
echo "📦 === Installing Argo CD CLI ==="
curl -sSL -o /usr/local/bin/argocd \
    "https://github.com/argoproj/argo-cd/releases/download/${ARGOCD_VERSION}/argocd-linux-amd64"
chmod +x /usr/local/bin/argocd

# Verify installations
echo "🔍 === Verifying installations ==="
echo "kind version: $(kind version)"
echo "kubectl version: $(kubectl version --client -o json | jq -r '.clientVersion.gitVersion')"
echo "argocd version: $(argocd version --client | grep 'argocd: ' | cut -d ' ' -f2)"

echo "✅ === Successfully installed all tools ==="
