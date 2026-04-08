# IS469 Deployment

This project was taken from the OpenTelemetry Demo repository: https://github.com/open-telemetry/opentelemetry-demo

Loki and Tempo were deployed as telemetry backends because they support API queries, which fits the needs of our telemetry tool.

Skaffold is used to manage deployment of the main application stack.

## Run Services

```bash
skaffold run --default-repo=us-central1-docker.pkg.dev/project-603c1fe8-b927-4fcf-92e/is469-registry
```

Apply Chaos Mesh and Loki/Tempo separately using the manifests in the `kubernetes` folder.

## Delete

```bash
skaffold delete
```
