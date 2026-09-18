#!/usr/bin/env bash

set -euo pipefail

CLUSTER_NAME="demo"
NAMESPACE="demo"
RELEASE_NAME="demo"
IMAGE_NAME="demo-service:local"

INGRESS_NAMESPACE="ingress-nginx"
INGRESS_REPO="https://kubernetes.github.io/ingress-nginx"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Checking required tools..."

command -v docker >/dev/null 2>&1 || {
    echo "ERROR: docker is not installed."
    exit 1
}

command -v kind >/dev/null 2>&1 || {
    echo "ERROR: kind is not installed."
    exit 1
}

command -v kubectl >/dev/null 2>&1 || {
    echo "ERROR: kubectl is not installed."
    exit 1
}

command -v helm >/dev/null 2>&1 || {
    echo "ERROR: helm is not installed."
    exit 1
}

echo "==> Checking Docker..."
docker info >/dev/null

echo "==> Creating or reusing kind cluster: ${CLUSTER_NAME}"

if kind get clusters | grep -qx "${CLUSTER_NAME}"; then
    echo "Cluster '${CLUSTER_NAME}' already exists. Reusing it."
else
    KIND_CONFIG="$(mktemp)"

    cat > "${KIND_CONFIG}" <<'EOF'
kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 30080
        hostPort: 8081
        protocol: TCP
EOF

    kind create cluster \
        --name "${CLUSTER_NAME}" \
        --config "${KIND_CONFIG}" \
        --wait 120s

    rm -f "${KIND_CONFIG}"
fi

echo "==> Using kind context..."

kubectl config use-context "kind-${CLUSTER_NAME}"

echo "==> Waiting for Kubernetes node..."

kubectl wait \
    --for=condition=Ready \
    node \
    --all \
    --timeout=120s

echo "==> Adding/updating ingress-nginx Helm repository..."

helm repo add ingress-nginx "${INGRESS_REPO}" --force-update

echo "==> Installing or upgrading ingress-nginx..."

helm upgrade --install ingress-nginx \
    ingress-nginx/ingress-nginx \
    --namespace "${INGRESS_NAMESPACE}" \
    --create-namespace \
    --set controller.service.type=NodePort \
    --set controller.service.nodePorts.http=30080

echo "==> Waiting for ingress-nginx controller..."

kubectl wait \
    --namespace "${INGRESS_NAMESPACE}" \
    --for=condition=ready \
    pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s

echo "==> Building Docker image..."

docker build \
    -t "${IMAGE_NAME}" \
    "${SCRIPT_DIR}/service"

echo "==> Loading image into kind..."

kind load docker-image "${IMAGE_NAME}" \
    --name "${CLUSTER_NAME}"

echo "==> Creating or reusing namespace: ${NAMESPACE}"

kubectl create namespace "${NAMESPACE}" \
    --dry-run=client \
    -o yaml | kubectl apply -f -

echo "==> Installing or upgrading Helm release: ${RELEASE_NAME}"

helm upgrade --install "${RELEASE_NAME}" \
    "${SCRIPT_DIR}/chart" \
    --namespace "${NAMESPACE}" \
    --create-namespace

echo "==> Waiting for application deployment..."

kubectl rollout status \
    deployment/"${RELEASE_NAME}" \
    --namespace "${NAMESPACE}" \
    --timeout=180s

echo
echo "========================================"
echo "Setup completed successfully!"
echo "========================================"
echo
echo "Cluster:  ${CLUSTER_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Release:  ${RELEASE_NAME}"
echo
echo "Verify:"
echo "  kubectl get pods -n ${NAMESPACE}"
echo "  kubectl get svc -n ${NAMESPACE}"
echo "  kubectl get ingress -n ${NAMESPACE}"
echo
echo "Test:"
echo '  curl -H "Host: demo.local" http://localhost:8081/'
echo '  curl -H "Host: demo.local" http://localhost:8081/healthz'