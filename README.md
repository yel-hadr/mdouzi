# Part 3 - K3d and Argo CD

## Goal

Part 3 replaces Vagrant with K3d. The setup script installs the tools needed for
the defense, creates a local K3d cluster, installs Argo CD, and deploys the
`wil42/playground` application into the `dev` namespace through GitOps.

The subject requires:

- Docker and K3d.
- Two namespaces: `argocd` and `dev`.
- Argo CD installed in `argocd`.
- An application deployed in `dev`.
- The application manifests synced from a public GitHub repository.
- Two application versions, `v1` and `v2`, demonstrated by changing the image tag
  in Git.

## Files

```text
p3/
+-- deployment.yaml
+-- confs/
|   +-- application.yaml
+-- scripts/
    +-- setup.sh
    +-- setup_server.sh
```

- `scripts/setup.sh` installs Docker, kubectl, and K3d when missing, creates the
  `iotcluster` K3d cluster, creates namespaces, installs Argo CD, and applies the
  Argo CD Application manifest.
- `scripts/setup_server.sh` currently performs the same setup as `setup.sh`.
- `confs/application.yaml` tells Argo CD to sync the application from the public
  GitHub repository.
- `deployment.yaml` is the Kubernetes deployment and service for
  `wil42/playground:v1`.

## Public Git Repository

The Argo CD Application currently points to:

```text
https://github.com/yel-hadr/mdouzi
```

with:

```yaml
targetRevision: HEAD
path: .
```

That repository must contain the Kubernetes manifest that deploys the playground
application. The image tag is changed there during evaluation to prove Argo CD
synchronizes the cluster.

## How To Run

From the repository root or this folder:

```bash
sudo bash p3/scripts/setup.sh
```

If you are already inside `p3`:

```bash
sudo bash scripts/setup.sh
```

The script creates a K3d cluster named `iotcluster` and maps the application port:

```text
localhost:8888 -> cluster load balancer port 8888
```

## Useful Checks

```bash
kubectl get ns
kubectl get pods -n argocd
kubectl get pods -n dev
kubectl get application -n argocd
curl http://localhost:8888/
```

Expected initial application response:

```json
{"status":"ok", "message": "v1"}
```

## Access Argo CD

Forward the Argo CD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

Get the initial admin password:

```bash
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" | base64 -d
```

Open:

```text
https://localhost:8080
```

Default username:

```text
admin
```

## Demonstrate Version Update

In the public GitHub repository used by Argo CD, change:

```yaml
image: wil42/playground:v1
```

to:

```yaml
image: wil42/playground:v2
```

Commit and push the change, then wait for Argo CD to sync. You can force a refresh
with:

```bash
kubectl annotate application playground -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
```

Check the result:

```bash
curl http://localhost:8888/
```

Expected updated response:

```json
{"status":"ok", "message": "v2"}
```

## Cleanup

```bash
k3d cluster delete iotcluster
```
