# Helm

## Overview

Helm is the package manager for Kubernetes. It lets you deploy, upgrade, and manage the hello-platform application using a reusable **chart** instead of raw manifests.

The chart lives in [charts/hello-platform/](../charts/hello-platform/) and packages all Kubernetes resources (Deployment, Service, Ingress, ConfigMap) into a single installable unit. Configuration is centralized in [values.yaml](../charts/hello-platform/values.yaml), making it easy to customize per environment without modifying templates.

### Chart Structure

```
charts/hello-platform/
├── Chart.yaml          # Chart metadata (name, version, appVersion)
├── values.yaml         # Default configuration values
├── templates/          # Kubernetes manifest templates
│   ├── _helpers.tpl    # Reusable template helpers (labels, names)
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── ingress.yaml
│   ├── configmap.yaml
│   ├── serviceaccount.yaml
│   ├── hpa.yaml        # Horizontal Pod Autoscaler (disabled by default)
│   ├── httproute.yaml  # Gateway API route (disabled by default)
│   └── NOTES.txt       # Post-install message
└── charts/             # Subcharts / dependencies (if any)
```

### Key values.yaml Fields

| Field | Default | Purpose |
|-------|---------|---------|
| `replicaCount` | `2` | Number of pod replicas |
| `image.repository` | `hello-platform` | Container image name |
| `image.tag` | `latest` | Container image tag |
| `service.port` | `80` | Service port |
| `service.targetPort` | `3000` | Container port |
| `ingress.enabled` | `true` | Enable/disable Ingress |
| `ingress.hosts[0].host` | `hello-platform.local` | Ingress hostname |
| `resources` | CPU 100m-200m, Memory 128Mi-256Mi | Resource requests/limits |
| `autoscaling.enabled` | `false` | Enable Horizontal Pod Autoscaler |
| `httpRoute.enabled` | `false` | Enable Gateway API HTTPRoute |

## Getting Started

### Prerequisites

- Helm CLI installed (`brew install helm` on macOS)
- A running Kubernetes cluster with `kubectl` configured
- Docker image built (`docker build -t hello-platform:latest .`)

### Lint the Chart

Always lint before installing to catch errors:

```bash
helm lint charts/hello-platform
```

### Dry-Run Install

Preview the rendered manifests without applying them:

```bash
helm install hello-platform charts/hello-platform --dry-run --debug -n hello-platform
```

### Install the Chart

```bash
helm install hello-platform charts/hello-platform -n hello-platform --create-namespace
```

This creates the namespace (if it doesn't exist) and installs all resources.

### Override Values at Install Time

```bash
helm install hello-platform charts/hello-platform -n hello-platform --create-namespace \
  --set replicaCount=3 \
  --set image.tag=v1.0.1
```

### Use a Values File Per Environment

Create environment-specific files:

```bash
# values-dev.yaml
replicaCount: 1
ingress:
  hosts:
    - host: hello-platform-dev.local
      paths:
        - path: /
          pathType: Prefix

# Install with dev values
helm install hello-platform charts/hello-platform -n hello-platform \
  -f charts/hello-platform/values-dev.yaml
```

## Commands Reference

| Command | Purpose |
|---------|---------|
| `helm lint charts/hello-platform` | Validate the chart for errors |
| `helm template <name> charts/hello-platform` | Render templates locally (no cluster needed) |
| `helm install <name> charts/hello-platform -n <namespace>` | Install the chart |
| `helm upgrade <name> charts/hello-platform -n <namespace>` | Upgrade an existing release |
| `helm upgrade --install <name> charts/hello-platform` | Install or upgrade (idempotent) |
| `helm rollback <name> <revision> -n <namespace>` | Rollback to a previous version |
| `helm uninstall <name> -n <namespace>` | Remove the release |
| `helm list -n <namespace>` | List installed releases |
| `helm status <name> -n <namespace>` | Show release status |
| `helm history <name> -n <namespace>` | View revision history |
| `helm get values <name> -n <namespace>` | Show computed values of a release |

## Troubleshooting

### Installation fails: "ConfigMap already exists and cannot be imported"

Existing resources were created manually (e.g., via `kubectl apply`). Helm can't adopt resources it didn't create. Delete them first:

```bash
kubectl delete configmap hello-platform-config -n hello-platform
kubectl delete deployment hello-platform -n hello-platform
kubectl delete service hello-platform -n hello-platform
kubectl delete ingress hello-platform -n hello-platform
```

Then reinstall:

```bash
helm install hello-platform charts/hello-platform -n hello-platform
```

### Lint errors: "nil pointer evaluating interface{}"

A template references a value not defined in `values.yaml`. Ensure all values referenced by templates exist, even if just set to a default:

```yaml
# Example: httproute.yaml checks .Values.httpRoute.enabled
# values.yaml must include:
httpRoute:
  enabled: false
```

### Pods not starting after upgrade

Check the release status and pod events:

```bash
helm status hello-platform -n hello-platform
kubectl get events -n hello-platform --sort-by='.lastTimestamp'
kubectl logs -l app.kubernetes.io/name=hello-platform -n hello-platform
```

If the issue persists, rollback to the previous working revision:

```bash
helm history hello-platform -n hello-platform
helm rollback hello-platform 1 -n hello-platform
```

### Ingress not routing traffic

Verify the ingress was created:

```bash
kubectl get ingress -n hello-platform
kubectl describe ingress hello-platform-hello-platform -n hello-platform
```

Ensure `ingress.enabled: true` in your values and that an nginx ingress controller is installed in the cluster.

### Chart changes not taking effect

If you edited templates but didn't upgrade:

```bash
helm upgrade hello-platform charts/hello-platform -n hello-platform
```

Use `--force` to trigger a rolling restart even if values haven't changed:

```bash
helm upgrade hello-platform charts/hello-platform -n hello-platform --force
```
