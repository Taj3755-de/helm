# sample-k8s-node-app

A tiny Node.js app demonstrating Docker + Kubernetes deployment.

## Build and Deploy

```bash
docker build -t <registry>/sample-node-app:v1 .
docker push <registry>/sample-node-app:v1
kubectl apply -f k8s/
kubectl get pods -o wide
kubectl get svc
```

Update the nodeSelector in `k8s/deployment.yaml` as needed.
