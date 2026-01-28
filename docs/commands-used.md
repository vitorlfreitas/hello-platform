# Hello Platform

## Overview

A demo application to review all steps within the process of building a Backstage application

## Prerequisites

## How to run

```bash
run npm install
```

```bash
npm run dev
```

```bash
npm run build
```

```bash
npm start
```

# Docker 

```bash
docker build -t hello-platform:latest . 
```
```bash
docker run -d -p 3000:3000 --name hello-platform hello-platform:latest
```
```bash
docker logs -f hello-platform
```
```bash
curl http://localhost:3000/health
```
```bash
docker stop hello-platform
```

```bash
docker rm hello-platform
```

## Using Docker Compose

```bash
docker-compose up -d
```

```bash
docker-compose logs -f
```

```bash
docker-compose down
```


## Kubernetes

I use Rancher Desktop

So, first check if it is running,

```bash
check the kubectl context

# Print the context selected
kubectl config current-context

# Check the context is set properly
kubectl config use-context rancher-desktop

# Check if it is running 
kubectl get nodes

kubectl apply -f k8s/manifests/namespace/dev-namespace.yaml
```

Apply for all files:
- configmap.yaml
- deployments.yaml
- ingress.yaml
- namespace.yaml
- service.yaml

