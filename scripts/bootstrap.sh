#!/usr/bin/env bash
set -eu

CLUSTER_NAME="${CLUSTER_NAME:-k8s-limits-cluster-test}"
ARGOCD_VERSION="${ARGOCD_VERSION:-v3.3.3}"
KUBE_PROMETHEUS_STACK_VERSION="${KUBE_PROMETHEUS_STACK_VERSION:-82.10.4}"

if kind get clusters 2>/dev/null | grep -q "^${CLUSTER_NAME}$"; then
	echo "ℹ️  Cluster '${CLUSTER_NAME}' already exists, skipping creation."
else
kind create cluster \
	--wait 120s \
	--config - <<EOF
apiVersion: kind.x-k8s.io/v1alpha4
kind: Cluster
name: ${CLUSTER_NAME}
nodes:
- role: control-plane
  extraPortMappings:
    - containerPort: 30080  # For ArgoCD NodePort
      hostPort: 8080
      protocol: TCP
EOF
fi

# Verify nodes are ready
echo "🔍 Checking cluster nodes..."
kubectl get nodes

echo "🚀 === Installing Argo CD in the 'argocd' namespace ==="
echo "📦 Using Argo CD version: ${ARGOCD_VERSION}"
kubectl create namespace argocd || echo "⚠️ Namespace 'argocd' already exists, skipping creation."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGOCD_VERSION}/manifests/install.yaml

# Install kube-prometheus-stack for monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts || echo "⚠️ Helm repo 'prometheus-community' already exists, skipping addition."
helm repo add vm https://victoriametrics.github.io/helm-charts/ || echo "⚠️ Helm repo 'vm' already exists, skipping addition."
helm repo update
helm install kube-prometheus-stack prometheus-community/kube-prometheus-stack --version ${KUBE_PROMETHEUS_STACK_VERSION} \
    --namespace monitoring \
    --create-namespace \
    --set alertmanager.enabled=false \
