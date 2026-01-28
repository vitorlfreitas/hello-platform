# Kubernetes

## Overview

Kubernetes runs the hello-platform application as a distributed, self-healing workload. The manifests in the [k8s/](../k8s/) directory define the following resources:

| Resource | File | Purpose |
|----------|------|---------|
| Namespace | `dev-namespace.yaml` | Isolates resources under `hello-platform` |
| ConfigMap | `app-configmap.yaml` | Stores environment variables (`NODE_ENV`, `PORT`, `LOG_LEVEL`) |
| Deployment | `app-deployment.yaml` | Manages 2 replicas with liveness/readiness probes and resource limits |
| Service | `app-service.yaml` | Exposes the app internally via ClusterIP (port 80 → 3000) |
| Ingress | `app-ingress.yaml` | Routes external traffic via nginx at `hello-platform.local` |

A [kustomization.yaml](../k8s/kustomization.yaml) is included to apply all resources together with shared labels and image management.

## Getting Started

### Prerequisites

- A local Kubernetes cluster (e.g., [Rancher Desktop](https://docs.rancherdesktop.io/), Minikube, or Kind)
- `kubectl` configured and pointing to your cluster
- The Docker image built (`docker build -t hello-platform:latest .`)

### Verify Your Cluster Is Running

```bash
# Check current context
kubectl config current-context

# Switch to Rancher Desktop (if applicable)
kubectl config use-context rancher-desktop

# Confirm nodes are ready
kubectl get nodes
```

### Apply All Manifests with Kustomize

```bash
kubectl apply -k k8s/
```

This creates the namespace, configmap, deployment, service, and ingress in one command.

### Apply Individually (alternative)

```bash
kubectl apply -f k8s/dev-namespace.yaml
kubectl apply -f k8s/app-configmap.yaml
kubectl apply -f k8s/app-deployment.yaml
kubectl apply -f k8s/app-service.yaml
kubectl apply -f k8s/app-ingress.yaml
```

### Verify the Deployment

```bash
# Check pods are running
kubectl get pods -n hello-platform

# Check all resources
kubectl get all -n hello-platform
```

### Test Locally via Port-Forward

```bash
kubectl port-forward svc/hello-platform 3000:80 -n hello-platform
```

Then in another terminal:

```bash
curl http://localhost:3000/health
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `kubectl apply -k k8s/` | Apply all manifests via Kustomize |
| `kubectl get pods -n hello-platform` | List pods |
| `kubectl get all -n hello-platform` | List all resources in the namespace |
| `kubectl logs -l app=hello-platform -n hello-platform` | View pod logs |
| `kubectl describe pod <pod-name> -n hello-platform` | Inspect a specific pod |
| `kubectl port-forward svc/hello-platform 3000:80 -n hello-platform` | Forward service to localhost |
| `kubectl delete -k k8s/` | Remove all manifests |
| `kubectl get events -n hello-platform` | View namespace events |

## Troubleshooting

### Pods stuck in `Pending`

Check events for resource or scheduling issues:

```bash
kubectl get events -n hello-platform --sort-by='.lastTimestamp'
```

Common causes:
- Insufficient node resources (CPU/memory limits too high)
- Image pull failure (check `imagePullPolicy`)

### Pods in `CrashLoopBackOff`

The container is crashing on startup. Check logs:

```bash
kubectl logs -l app=hello-platform -n hello-platform --previous
```

### Pods in `ImagePullBackOff`

The image isn't available to the cluster. Since the image is built locally:

```bash
# Verify the image exists
docker images hello-platform

# If using Rancher Desktop or Minikube, the local images may need specific handling
# For Rancher Desktop, local images are shared automatically
# For Minikube:
minikube image load hello-platform:latest
```

### Service not reachable

Confirm the service selector matches the pod labels:

```bash
kubectl describe svc hello-platform -n hello-platform
kubectl get pods -n hello-platform --show-labels
```

### Ingress returns 404

Verify the ingress controller is installed:

```bash
kubectl get pods -n ingress-nginx
```

If not installed, install nginx ingress for your cluster and ensure the host resolves (add `hello-platform.local` to `/etc/hosts` pointing to your cluster's load balancer IP).
