# IS469 Deployment

This project is based on the [OpenTelemetry Demo](https://github.com/open-telemetry/opentelemetry-demo).

The deployment includes:

- The OpenTelemetry demo application
- Loki for logs
- Tempo for traces
- Chaos Mesh for chaos experiments

Skaffold manages the Kubernetes deployment so the full stack can be started with a single command.

## Prerequisites

Install these tools locally before deploying:

- `gcloud`
- `kubectl`
- `skaffold`
- Docker

You also need:

- A Google Cloud project with billing enabled
- A GKE Standard cluster
- An Artifact Registry Docker repository

Use a GKE Standard cluster, not Autopilot, because Chaos Mesh requires node-level access that is typically restricted in Autopilot.

## 1. Set Your Environment Variables

Update these values for your own project before running the commands below:

```bash
export PROJECT_ID="your-gcp-project-id"
export REGION="us-central1"
export CLUSTER_NAME="is469-cluster"
export REPOSITORY="is469-registry"
```

If you are using PowerShell instead of Bash:

```powershell
$env:PROJECT_ID="your-gcp-project-id"
$env:REGION="us-central1"
$env:CLUSTER_NAME="is469-cluster"
$env:REPOSITORY="is469-registry"
```

## 2. Create the GKE Cluster

Authenticate and point `gcloud` at your project:

```bash
gcloud auth login
gcloud config set project $PROJECT_ID
gcloud services enable container.googleapis.com artifactregistry.googleapis.com
```

Create a GKE Standard cluster:

```bash
gcloud container clusters create $CLUSTER_NAME \
  --region $REGION \
  --num-nodes 3
```

## 3. Create the Artifact Registry Repository

If you do not already have a Docker repository in Artifact Registry, create one:

```bash
gcloud artifacts repositories create $REPOSITORY \
  --repository-format=docker \
  --location=$REGION \
  --description="IS469 container images"
```

Configure Docker to push images to Artifact Registry:

```bash
gcloud auth configure-docker "$REGION-docker.pkg.dev"
```

## 4. Add GKE Credentials to Your Local Machine

Pull the cluster credentials into your local kubeconfig so `kubectl` and `skaffold` can connect to the cluster:

```bash
gcloud container clusters get-credentials $CLUSTER_NAME --region $REGION
```

Verify the connection:

```bash
kubectl config current-context
kubectl get nodes
```

## 5. Deploy Everything with Skaffold

This repo is configured so one Skaffold command deploys:

- The OpenTelemetry demo application
- Loki
- Tempo
- Chaos Mesh

Run:

```bash
skaffold run --default-repo=$REGION-docker.pkg.dev/$PROJECT_ID/$REPOSITORY
```

Skaffold builds the images, pushes them to Artifact Registry, and applies the Kubernetes manifests in the `otel-demo` namespace.

## 6. Connect to the Services Locally

Use the helper script to create port-forwards for the main services:

```bash
./connect.sh
```

This exposes:

- Frontend: `http://localhost:8080`
- Loki: `http://localhost:3100`
- Tempo: `http://localhost:3200`
- Prometheus: `http://localhost:9090`
- FlagD: `http://localhost:4000`
- Chaos Mesh: `http://localhost:2333`

## Delete the Deployment

Remove everything deployed by Skaffold:

```bash
skaffold delete
```
