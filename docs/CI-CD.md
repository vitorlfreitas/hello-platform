# CI/CD with GitHub Actions

## Overview

This project uses **GitHub Actions** for CI/CD (Continuous Integration and Continuous Deployment). Every push to `main` automatically builds a Docker image, pushes it to a container registry, and triggers a deployment via ArgoCD.

No manual steps. No manual deploys. Push code — everything else is handled.

---

## How It All Fits Together

```
Developer                GitHub Actions              ghcr.io              ArgoCD              Kubernetes
    |                         |                        |                    |                     |
    |-- git push to main ---> |                        |                    |                     |
    |                         |-- docker build ------> |                    |                     |
    |                         |-- docker push -------> |                    |                     |
    |                         |-- update values.yaml   |                    |                     |
    |                         |-- git commit + push -> |                    |                     |
    |                         |                        |  <-- detects change (ArgoCD watches repo)
    |                         |                        |                    |-- helm upgrade ---> |
    |                         |                        |                    |                     |-- pods running
```

---

## The Workflow File

Located at [.github/workflows/deploy.yaml](../.github/workflows/deploy.yaml)

### Trigger

```yaml
on:
  push:
    branches:
      - main
```

Runs automatically on every push to `main`. No manual trigger needed.

### Permissions

```yaml
permissions:
  contents: write    # Push updated values.yaml back to the repo
  packages: write    # Push Docker image to ghcr.io
```

Both are granted via the built-in `GITHUB_TOKEN` — no manual secrets or API keys required.

### Steps Breakdown

| Step | Action | What It Does |
|---|---|---|
| 1 | Checkout | Clones the repo into the GitHub runner |
| 2 | Login to ghcr.io | Authenticates using `GITHUB_TOKEN` (automatic) |
| 3 | Build and push | Builds the Docker image, tags it with the git commit SHA, pushes to ghcr.io |
| 4 | Update values.yaml | Replaces the `image.tag` with the new commit SHA |
| 5 | Commit and push | Commits the updated tag back to `main` — ArgoCD detects this and deploys |

---

## Why Commit SHA as the Image Tag?

Each build is tagged with the exact git commit that produced it:

```
ghcr.io/vitorlfreitas/hello-platform:a1b2c3d4e5f6...
                                      ↑
                                      git commit SHA
```

**Benefits:**
- **Traceable** — you can always know exactly which code version is running
- **Unique** — no tag conflicts or overwriting (unlike `latest`)
- **Rollback-friendly** — revert values.yaml to a previous SHA to roll back instantly

---

## Why No Infinite Loop?

The workflow pushes a commit back to `main` (Step 5). You might expect this to trigger the workflow again, creating an infinite loop.

It doesn't, because GitHub Actions uses `GITHUB_TOKEN` for the push. By design, **pushes made with `GITHUB_TOKEN` do not trigger new workflow runs**. This is a built-in safety mechanism from GitHub.

---

## Why No Manual Credentials?

Everything stays within the GitHub ecosystem:

```
GitHub Actions  ←→  ghcr.io  ←→  Your repo
        ↑              ↑            ↑
        └──────────────┴────────────┘
              All trusted by GITHUB_TOKEN
```

`GITHUB_TOKEN` is automatically created by GitHub for every workflow run. It has permission to:
- Push images to ghcr.io (your account's container registry)
- Read and write your repository

You would only need manual credentials if you pushed to an **external** registry like Docker Hub, AWS ECR, or a self-hosted registry.

---

## The Full Automation Loop

Once set up, this is the ongoing cycle:

```
1. You write code and push to main
2. GitHub Actions triggers automatically
3. Docker image is built and pushed to ghcr.io
4. values.yaml is updated with the new image tag
5. Updated values.yaml is committed back to main
6. ArgoCD detects the change in the repo
7. ArgoCD re-renders the Helm chart with the new tag
8. ArgoCD applies the updated manifests to Kubernetes
9. New pods start with the fresh image
```

**Your involvement:** Step 1 only. Steps 2–9 are fully automated.

---

## Image Registry: ghcr.io

Images are stored at:

```
ghcr.io/vitorlfreitas/hello-platform:<commit-sha>
```

**Why ghcr.io:**
- Free (no cost for public repos)
- Built into GitHub (no extra account)
- Authenticated automatically by `GITHUB_TOKEN`
- Public repo = public package (no pull authentication needed)

---

## Troubleshooting

### Workflow fails at "Build and push"

- Check the GitHub Actions logs for the exact error
- Ensure the Dockerfile has no syntax errors
- Verify the repo permissions allow package creation

### Pods show `ImagePullBackOff`

- The cluster can't pull the image from ghcr.io
- If the repo is public, the package should be public too
- If not, go to `github.com/vitorlfreitas/hello-platform/packages` and set visibility to public

### ArgoCD doesn't sync after workflow completes

- Check the ArgoCD UI for any sync errors
- Verify the Application is watching the correct branch (`main`)
- The workflow commit should appear in your repo — confirm it's there

### Workflow runs but values.yaml doesn't update

- Check Step 4 logs in the GitHub Actions UI
- The `sed` command targets the `tag:` line in `charts/hello-platform/values.yaml`
- Ensure no extra whitespace or formatting changed the line structure

---

## Commands Reference

| Command | Purpose |
|---|---|
| `git push origin main` | Trigger the CI/CD pipeline |
| `kubectl get pods -n hello-platform` | Verify new pods are running |
| `kubectl rollout history deployment/hello-platform -n hello-platform` | View deployment history |
| `kubectl rollout undo deployment/hello-platform -n hello-platform` | Roll back to previous version |
