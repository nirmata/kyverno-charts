# Go Agent Remediator Helm Chart

This Helm chart deploys Remediator Service agent in a Kubernetes cluster.

For installation, refer to the [documentation](https://docs.nirmata.io/docs/agents/service-agents/remediator/getting_started/).

## Configuration

### Core Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of controller replicas | `1` |
| `image.repository` | Container image repository | `ghcr.io/nirmata/go-agent-remediator` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `logging.verbosity` | Log verbosity level (0=info, 1=audit+info, 2=debug+audit+info) | `0` |
| `logging.enableAudit` | Enable audit logging (equivalent to verbosity >= 1) | `false` |

*Note: Image tag is automatically set to `Chart.yaml` appVersion*

