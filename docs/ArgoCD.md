# ArgoCD

## What is ArgoCD?

ArgoCD is a **GitOps continuous delivery tool** for Kubernetes. It watches a git repository and automatically deploys whatever is in it to your cluster — no manual `kubectl apply` or `helm install` needed.

The core idea behind GitOps is simple: **your git repo is the source of truth**. If you want something deployed, you push it to git. ArgoCD handles the rest.

```
Code change  →  Push to git  →  ArgoCD detects change  →  Deploys to K8s
```

### Why ArgoCD?

| Without ArgoCD | With ArgoCD |
|---|---|
| You manually run `helm install` or `kubectl apply` | Deploys automatically on every push |
| Easy to forget a step or deploy the wrong version | Git history = deployment history |
| No visibility into what's running vs. what's in the repo | Dashboard shows sync status, diffs, and health |
| Someone manually changes K8s — it drifts | `selfHeal` detects and fixes drift automatically |

### Key Concepts

- **Application** — an ArgoCD resource that says "watch this repo, deploy this chart to this namespace"
- **Sync** — the act of applying the git state to the cluster
- **Prune** — delete K8s resources that were removed from the chart
- **Self-Heal** — automatically fix resources if someone manually changes them
- **Target Revision** — the git branch or tag ArgoCD watches (e.g., `main`)

---

## Prerequisites

- Docker image built (`docker build -t hello-platform:latest .`)
- A local Kubernetes cluster (e.g., [Rancher Desktop](https://docs.rancherdesktop.io/), Minikube, or Kind)
- `kubectl` configured and pointing to your cluster
- Your code pushed to a remote git repo (GitHub, GitLab, etc.)

---

## Step 1 — Install ArgoCD

ArgoCD runs as a set of pods inside your cluster. We install it into its own namespace so it stays isolated from your app.

```bash
# Create the ArgoCD namespace
kubectl create namespace argocd

# Install ArgoCD (official stable manifests)
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for all pods to be ready
kubectl wait --for=condition=ready pod --all -n argocd --timeout=120s

# Confirm everything is up
kubectl get pods -n argocd
```

### What each ArgoCD pod does

| Pod | Role |
|---|---|
| `argocd-server` | The UI and API you interact with |
| `argocd-application-controller` | Watches the cluster and syncs state |
| `argocd-repo-server` | Clones git repos and renders Helm charts |
| `argocd-dex-server` | Handles authentication |
| `argocd-redis` | Cache and message queue between components |

---

## Step 2 — Access the ArgoCD UI

ArgoCD's web interface is not exposed externally by default. Port-forward it to your local machine.

**Terminal 1 — keep this running:**

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

**Open your browser:**

```
https://localhost:8080
```

**Terminal 2 — get the login password:**

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

**Login credentials:**

```
Username: admin
Password: (output from the command above)
```

---

## Step 3 — Create an ArgoCD Application

An Application tells ArgoCD where your code lives, what to deploy, and where to deploy it.

### Option A — Via the UI

1. Click **New Application** in the ArgoCD dashboard
2. Fill in the fields using the spec below
3. Click **Create**

### Option B — Via YAML manifest

Create a file (e.g., `argocd/application.yaml`) with this content:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: hello-platform
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/YOUR_USERNAME/hello-platform.git
    targetRevision: main
    path: charts/hello-platform
    helm:
      values: |
        replicaCount: 1
  destination:
    server: https://kubernetes.default.svc
    namespace: hello-platform
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
```

Apply it:

```bash
kubectl apply -f argocd/application.yaml
```

### Field reference

| Field | Value | Why |
|---|---|---|
| `source.repoURL` | Your GitHub repo URL | Where ArgoCD clones from |
| `source.path` | `charts/hello-platform` | Path to the Helm chart inside the repo |
| `source.targetRevision` | `main` | Branch to watch for changes |
| `source.helm.values` | `replicaCount: 1` | Override values (e.g., fewer replicas locally) |
| `destination.server` | `https://kubernetes.default.svc` | Your local cluster |
| `destination.namespace` | `hello-platform` | Namespace for the deployed app |
| `syncPolicy.automated.prune` | `true` | Delete resources removed from the chart |
| `syncPolicy.automated.selfHeal` | `true` | Auto-fix if someone manually changes K8s |

---

## Step 4 — Verify the Deployment

```bash
# Check pods are running
kubectl get pods -n hello-platform

# Check all resources ArgoCD created
kubectl get all -n hello-platform
```

### Test the app

**Terminal 1 — port-forward the Service:**

```bash
kubectl port-forward svc/hello-platform 3000:80 -n hello-platform
```

**Terminal 2 — hit the health endpoint:**

```bash
curl http://localhost:3000/health
```

---

## How the GitOps Loop Works

Once the Application is created and synced, this is the ongoing cycle:

```
1. You change code or chart values
2. You commit and push to main
3. ArgoCD detects the change (polls every ~30s)
4. ArgoCD re-renders the Helm chart
5. ArgoCD applies the new manifests to K8s
6. Your app updates — no manual action needed
```

### Testing it yourself

1. Edit `charts/hello-platform/values.yaml` — change `replicaCount` to `2`
2. Commit and push to GitHub
3. Watch the ArgoCD UI — it will show "syncing" then "synced"
4. Run `kubectl get pods -n hello-platform` — you'll see 2 pods

---

## Tearing Down

Remove the application but keep ArgoCD installed:

```bash
kubectl delete application hello-platform -n argocd
```

Remove ArgoCD entirely:

```bash
kubectl delete namespace argocd
```

---

## Commands Reference

| Command | Purpose |
|---|---|
| `kubectl create namespace argocd` | Create the ArgoCD namespace |
| `kubectl apply -n argocd -f <url>` | Install ArgoCD manifests |
| `kubectl get pods -n argocd` | List ArgoCD pods |
| `kubectl port-forward svc/argocd-server -n argocd 8080:443` | Access the UI locally |
| `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" \| base64 -d` | Get the admin password |
| `kubectl apply -f argocd/application.yaml` | Create an Application via CLI |
| `kubectl get pods -n hello-platform` | Verify app deployment |
| `kubectl delete application hello-platform -n argocd` | Remove the application |
| `kubectl delete namespace argocd` | Remove ArgoCD entirely |
