# Deployment Flow

End-to-end guide from building your TypeScript app to running it on Kubernetes via Helm.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) installed and running
- A local Kubernetes cluster (e.g., [Rancher Desktop](https://docs.rancherdesktop.io/), Minikube, or Kind)
- `kubectl` configured and pointing to your cluster
- Helm CLI installed (`brew install helm` on macOS)

---

## Step 1 — Build the Docker Image

Compile your TypeScript and package it into a container:

```bash
docker build -t hello-platform:latest .
```

Verify it was built:

```bash
docker images hello-platform
```

---

## Step 2 — Verify Locally

Run the container on your machine to confirm it works before deploying to Kubernetes:

```bash
docker run -d -p 3000:3000 --name hello-platform hello-platform:latest
curl http://localhost:3000/health
docker stop hello-platform && docker rm hello-platform
```

---

## Step 3 — Confirm Your Kubernetes Cluster Is Running

```bash
kubectl config current-context
kubectl get nodes
```

If using Rancher Desktop, local Docker images are shared with the cluster automatically. 

If using Minikube:

```bash
minikube image load hello-platform:latest
```

---

## Step 4 — Lint the Helm Chart

Catch any template or values errors before deploying:

```bash
helm lint charts/hello-platform
```

---

## Step 5 — Dry-Run the Install

Preview exactly what Kubernetes will receive without applying anything:

```bash
helm install hello-platform charts/hello-platform \
  -n hello-platform --create-namespace --dry-run --debug
```

---

## Step 6 — Deploy with Helm

Install the chart into a dedicated namespace:

```bash
helm install hello-platform charts/hello-platform \
  -n hello-platform --create-namespace
```

---

## Step 7 — Verify the Deployment

```bash
# Are the pods running?
kubectl get pods -n hello-platform

# Are all resources created?
kubectl get all -n hello-platform

# What's the release status?
helm status hello-platform -n hello-platform
```

---

## Step 8 — Test the App

Port-forward the Service to your local machine:

```bash
kubectl port-forward svc/hello-platform 3000:80 -n hello-platform
```

Then in another terminal:

```bash
curl http://localhost:3000/health
```

---

## Upgrading

When you release a new version, rebuild the image and upgrade the release:

```bash
docker build -t hello-platform:v1.1.0 .
helm upgrade hello-platform charts/hello-platform -n hello-platform --set image.tag=v1.1.0
```

---

## Tearing Down

```bash
helm uninstall hello-platform -n hello-platform
kubectl delete namespace hello-platform
```
