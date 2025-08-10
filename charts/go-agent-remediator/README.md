# Go Agent Remediator Helm Chart

This Helm chart deploys the Go Agent Remediator in a Kubernetes cluster. The remediator agent works with ArgoCD hub clusters to monitor applications, detect policy violations, and create automated remediation pull requests using AI models.

## What Gets Deployed

This chart creates:
- **Deployment**: The remediator agent controller
- **LLMConfig**: AI model configuration (Bedrock/Azure OpenAI)
- **ToolConfig**: External tool configuration (GitHub)
- **Remediator**: Main orchestration resource with targets, schedule, and actions
- **RBAC**: ClusterRole and bindings for required permissions

## Quick Start

1. **Create required secrets first:**
```bash
# AWS Bedrock credentials
kubectl create secret generic aws-bedrock-credentials \
  --from-literal=aws_access_key_id=YOUR_ACCESS_KEY \
  --from-literal=aws_secret_access_key=YOUR_SECRET_KEY \
  --namespace your-namespace

# GitHub token  
kubectl create secret generic github-token \
  --from-literal=token=YOUR_GITHUB_TOKEN \
  --namespace your-namespace
```

2. **Install the chart:**
```bash
helm install remediator ./charts/go-agent-remediator \
  --namespace your-namespace \
  --create-namespace \
  --set llm.model="anthropic.claude-3-sonnet-20240229-v1:0" \
  --set llm.region="us-west-2" \
  --set llm.secretName="aws-bedrock-credentials" \
  --set tool.secretName="github-token" \
  --set remediator.target.clusterNames="{cluster-1,cluster-2}"
```

## Configuration

### Core Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of controller replicas | `1` |
| `image.repository` | Container image repository | `ghcr.io/nirmata/go-agent-remediator` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |

*Note: Image tag is automatically set to Chart.yaml appVersion*

### LLM Configuration

Configure your AI model provider:

```yaml
llm:
  enabled: true
  provider: bedrock                           # Currently supports "bedrock"
  model: "anthropic.claude-3-sonnet-20240229-v1:0"
  region: "us-west-2"
  secretName: "aws-bedrock-credentials"       # Secret with AWS credentials
  secretKey: "aws_access_key_id"              # Optional, key in secret
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `llm.enabled` | Create LLMConfig resource | `true` |
| `llm.provider` | LLM provider type | `bedrock` |
| `llm.model` | Model ID or ARN | `""` |
| `llm.region` | AWS region for Bedrock | `""` |
| `llm.secretName` | Secret containing credentials | `""` |
| `llm.secretKey` | Key within secret | `"aws_access_key_id"` |

### Tool Configuration

Configure external tools (GitHub for PRs):

```yaml
tool:
  enabled: true
  name: github-tool                           # ToolConfig name
  type: github                                # Tool type
  secretName: "github-token"                  # Secret with GitHub token
  secretKey: "token"                          # Key in secret (optional)
  defaults:
    prBranchPrefix: remediation-
    prTitleTemplate: "[Auto-Remediation] Fix policy violations"
    commitMessageTemplate: "Auto-fix: Remediate policy violations"
```

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tool.enabled` | Create ToolConfig resource | `true` |
| `tool.name` | ToolConfig resource name | `github-tool` |
| `tool.type` | Tool type | `github` |
| `tool.secretName` | Secret containing token | `"github-token"` |
| `tool.secretKey` | Key within secret | `"token"` |

### Remediator Configuration

Main orchestration configuration:

```yaml
remediator:
  enabled: true
  name: nirmata-remediator
  environment:
    localCluster: false                       # Must be false for ArgoCD hub
    argoCD:
      hub: true                               # Must be true for ArgoCD hub
  target:
    clusterNames: ["cluster-1", "cluster-2"] # Target clusters
    clusterServerUrls: []                     # Optional validation URLs
    argoAppSelector:                          # App selection criteria
      allApps: true                           # Select all apps, OR:
      # names: ["app-1", "app-2"]             # Specific app names, OR:
      # labelSelector:                        # Label-based selection
      #   matchLabels:
      #     team: platform
  remediation:
    schedule: "0 9 * * 1"                     # Cron schedule (Mon 9am)
    matchSeverity: ["high", "critical"]       # OPTIONAL: Policy severity filter
    actions:
      - type: CreateGithubPR                  # Action type
        toolRefName: github-tool              # Reference to ToolConfig
```

### Policy Filtering

Policy filters are **optional**. If not specified, the remediator will process all policy violations without severity filtering:

```yaml
remediation:
  schedule: "0 9 * * 1"
  # matchSeverity omitted - processes all violations
  actions:
    - type: CreateGithubPR
      toolRefName: github-tool
```

To filter by severity levels:
```yaml
remediation:
  schedule: "0 9 * * 1"
  matchSeverity: ["high", "critical"]  # Only process high/critical violations
  actions:
    - type: CreateGithubPR
      toolRefName: github-tool
```

### Application Selection

The `argoAppSelector` supports three selection methods:

1. **Select all applications:**
```yaml
argoAppSelector:
  allApps: true
```

2. **Select by application names:**
```yaml
argoAppSelector:
  names:
    - web-frontend
    - api-backend
    - payment-service
```

3. **Select by labels:**
```yaml
argoAppSelector:
  labelSelector:
    matchLabels:
      team: platform
      environment: production
    matchExpressions:
      - key: criticality
        operator: In
        values: ["high", "critical"]
```

4. **Combined selection (AND logic):**
```yaml
argoAppSelector:
  names: ["critical-app"]
  labelSelector:
    matchLabels:
      team: platform
```

### Resource Configuration

```yaml
resources:
  limits:
    memory: 512Mi                             # Memory limit (CPU limits removed - anti-pattern)
  requests:
    cpu: 100m                                 # CPU request for scheduling
    memory: 128Mi                             # Memory request
```

## Examples

### Basic Setup
```yaml
# values.yaml
llm:
  model: "anthropic.claude-3-sonnet-20240229-v1:0"
  region: "us-west-2"
  secretName: "aws-bedrock-credentials"

tool:
  secretName: "github-token"

remediator:
  target:
    clusterNames: ["production-cluster"]
    argoAppSelector:
      allApps: true
```

### Advanced Setup with Label Selection
```yaml
# values.yaml
llm:
  model: "anthropic.claude-3-sonnet-20240229-v1:0"
  region: "us-west-2"
  secretName: "aws-bedrock-credentials"

tool:
  secretName: "github-token"
  defaults:
    prBranchPrefix: "auto-fix/"
    prTitleTemplate: "[Security] Fix violations in {{.Application}}"

remediator:
  target:
    clusterNames: ["prod-east", "prod-west"]
    argoAppSelector:
      labelSelector:
        matchLabels:
          team: security
          criticality: high
  remediation:
    schedule: "0 2 * * *"                     # Run at 2am daily
    matchSeverity: ["critical"]               # Only critical violations
```

## Prerequisites

1. **ArgoCD Hub Cluster**: Must be deployed in an ArgoCD hub cluster
2. **Policy Engine**: Kyverno or similar must be generating PolicyReports
3. **Secrets**: AWS Bedrock credentials and GitHub token
4. **RBAC**: Chart creates required ClusterRole permissions

## Troubleshooting

### Common Issues

1. **LLMConfig not working:**
   - Verify AWS credentials in secret
   - Check Bedrock model availability in your region
   - Ensure IAM permissions for Bedrock access

2. **No applications selected:**
   - Verify `argoAppSelector` configuration
   - Check ArgoCD Application labels/names
   - Ensure clusters exist in ArgoCD

3. **GitHub PR creation fails:**
   - Verify GitHub token permissions
   - Check repository access
   - Ensure token has PR creation rights

### Debugging

Check the controller logs:
```bash
kubectl logs -n your-namespace deployment/remediator-go-agent-remediator -f
```

Check resource status:
```bash
kubectl get remediator,llmconfig,toolconfig -n your-namespace
```

## Uninstalling

```bash
helm uninstall remediator -n your-namespace
```

Note: This removes the deployment and CRDs but preserves secrets.