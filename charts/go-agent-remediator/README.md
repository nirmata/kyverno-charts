# Go Agent Remediator Helm Chart

This Helm chart deploys the Go Agent Remediator operator in a Kubernetes cluster. The operator works with ArgoCD to monitor applications, detect policy violations, and create automated remediation pull requests.

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- ArgoCD installed in the cluster (if using ArgoCD integration)

## Installing the Chart

1. Add the Helm repository (replace with your actual repository):
```bash
helm repo add your-repo https://your-helm-repo.example.com
helm repo update
```

2. Install the chart:
```bash
helm install go-agent-remediator your-repo/go-agent-remediator \
  --namespace your-namespace \
  --create-namespace \
  --values values.yaml
```

## Configuration

The following table lists the configurable parameters of the Go Agent Remediator chart and their default values.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of operator replicas | `1` |
| `image.repository` | Operator image repository | `your-registry/go-agent-remediator` |
| `image.tag` | Operator image tag | `latest` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `operator.environment.localCluster` | Whether running in local cluster | `false` |
| `operator.environment.argoCD.hub` | Whether this is an ArgoCD hub cluster | `true` |
| `resources.limits.cpu` | CPU limit | `500m` |
| `resources.limits.memory` | Memory limit | `512Mi` |
| `resources.requests.cpu` | CPU request | `100m` |
| `resources.requests.memory` | Memory request | `128Mi` |

### Operator Configuration

The operator can be configured using the following sections in your values.yaml:

1. Environment Configuration:
```yaml
operator:
  environment:
    localCluster: false
    argoCD:
      hub: true
```

### Target Configuration

The operator supports a unified target configuration that applies a single application selector across multiple clusters:

```yaml
operator:
  target:
    # Example 1: Multiple clusters with specific application names
    clusterNames:
      - cluster1
      - cluster2
      - cluster3
    clusterServerUrls:  # Optional for validation/filtering
      - "https://cluster1.example.com"
      - "https://cluster2.example.com"
    argoAppSelector:
      names:
        - web-frontend
        - api-service
        - payment-processor
      
    # Example 2: Multiple clusters with label-based selection
    # clusterNames:
    #   - production-cluster
    #   - staging-cluster
    # argoAppSelector:
    #   labelSelector:
    #     matchLabels:
    #       team: platform
    #       environment: production
    #     matchExpressions:
    #       - key: criticality
    #         operator: In
    #         values: ["high", "critical"]
    
    # Example 3: Multiple clusters selecting all applications
    # clusterNames:
    #   - dev-cluster
    #   - test-cluster
    # argoAppSelector:
    #   allApps: true
    
    # Example 4: Combined criteria (applications must match ALL criteria)
    # clusterNames:
    #   - production-cluster
    # argoAppSelector:
    #   names:
    #     - critical-app
    #   labelSelector:
    #     matchLabels:
    #       team: platform
```

#### Target Configuration Options

| Field | Type | Description |
|-------|------|-------------|
| `clusterNames` | `[]string` | List of cluster names to target for remediation |
| `clusterServerUrls` | `[]string` | Optional list of cluster server URLs for validation/filtering |
| `argoAppSelector` | `ArgoAppSelector` | Application selector that applies to all clusters |

#### ArgoAppSelector Options

| Field | Type | Description |
|-------|------|-------------|
| `names` | `[]string` | List of specific Argo application names to select |
| `labelSelector` | `metav1.LabelSelector` | Kubernetes label selector to match applications |
| `allApps` | `bool` | Select all applications in all clusters (overrides other criteria) |

**Selection Logic:**
- **Single selector**: One ArgoAppSelector applies to all specified clusters
- **Multiple criteria**: When multiple selection methods are specified, applications must match ALL criteria (AND logic)
- **No default selection**: If `argoAppSelector` is omitted, no applications will be selected
- **Priority**: `allApps: true` overrides all other selection criteria

3. Remediation Settings:
```yaml
operator:
  remediation:
    triggers:
      - schedule:
          crontab: "0 * * * *"
    filters:
      policySelector:
        matchSeverity:
          - high
          - critical
    actions:
      - type: github-pr
        toolRef:
          name: github-tool
          namespace: default
    provider:
      providerType: bedrock
      bedrockModel: ""
```

4. Tool Configurations:
```yaml
toolConfigs:
  - name: github-tool
    type: github
    org: your-org
    credentials:
      secretRef:
        name: github-secret
        key: token
    defaults:
      repoUrl: ""
      baseBranch: main
      targetPath: ""
      prBranchPrefix: fix/
      commitAuthor:
        name: Bot
        email: bot@example.com
```

## Uninstalling the Chart

To uninstall/delete the `go-agent-remediator` deployment:

```bash
helm delete go-agent-remediator -n your-namespace
``` 