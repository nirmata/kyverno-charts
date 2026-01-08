# Nirmata Agent Helm Chart

This Helm chart deploys Nirmata Service Agents in a Kubernetes cluster.

For installation, refer to the [documentation](https://docs.nirmata.io/docs/agents/service-agents/remediator/getting_started/).

## Configuration

### Core Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of controller replicas | `1` |
| `image.repository` | Container image repository | `reg.nirmata.io/nirmata/go-nirmata-agent` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `logging.verbosity` | Log verbosity level (0=info, 1=audit+info, 2=debug+audit+info) | `0` |
| `logging.enableAudit` | Enable audit logging (equivalent to verbosity >= 1) | `false` |

*Note: Image tag is automatically set to `Chart.yaml` appVersion*

### LLM Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `llm.enabled` | Enable creation of LLMConfig resource | `true` |
| `llm.provider` | LLM provider (bedrock, azure-openai, nirmataAI) | `nirmataAI` |
| `llm.nirmataAI.model` | Model name for Nirmata AI | `""` |
| `llm.bedrock.model` | AWS Bedrock model name | `""` |
| `llm.bedrock.region` | AWS region | `""` |
| `llm.bedrock.secretRef.name` | Secret containing AWS credentials | `""` |
| `llm.azureOpenAI.endpoint` | Azure OpenAI endpoint | `""` |
| `llm.azureOpenAI.deploymentName` | Azure deployment name | `""` |
| `llm.azureOpenAI.secretRef.name` | Secret containing API key | `""` |

### Tool Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tool.enabled` | Enable creation of ToolConfig resource | `true` |
| `tool.name` | Tool name | `github-tool` |
| `tool.type` | Tool type (currently only github) | `github` |
| `tool.credentials.method` | Auth method (pat or app) | `pat` |
| `tool.credentials.pat.secret.name` | Secret containing GitHub PAT | `github-token` |
| `tool.credentials.app.appId` | GitHub App ID | `""` |

### Remediator Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `remediator.enabled` | Enable creation of Remediator resource | `false` |
| `remediator.name` | Remediator resource name | `nirmata-agent` |
| `remediator.environment.type` | Environment type (localCluster or argoHub) | `argoHub` |
| `remediator.remediation.schedule` | Cron schedule for remediation | `0 */6 * * *` |
| `remediator.remediation.eventPolling.enabled` | Enable PR event polling | `true` |
| `remediator.remediation.actions` | List of remediation actions | `[{type: CreatePR}]` |

### Agent Configuration

The Agent resource enables autonomous AI-powered operations on your Kubernetes clusters.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `agent.enabled` | Enable creation of Agent resource | `false` |
| `agent.name` | Agent resource name | `<release-name>-agent` |
| `agent.prompt` | **REQUIRED** - Custom instruction defining agent behavior (min 10 chars) | `""` |
| `agent.tools` | List of additional tool names (email, send_slack_message, etc.) | `[]` |
| `agent.environment.type` | Environment type (localCluster or argoHub) | `localCluster` |
| `agent.triggers[].schedule.crontab` | Cron expression for execution schedule | `0 */6 * * *` |
| `agent.llmConfigRef.name` | LLMConfig resource to use | `<release-name>-llm` |

#### Agent Target Configuration

**For LocalCluster:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `agent.target.localCluster.repoNamespaceMappingRef.name` | ConfigMap with repo-namespace mappings | `""` |
| `agent.target.localCluster.repoNamespaceMappingRef.namespace` | ConfigMap namespace | `<release-namespace>` |

**For ArgoHub:**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `agent.target.argoHub.clusterNames` | List of cluster names to target | `[]` |
| `agent.target.argoHub.clusterServerUrls` | List of cluster server URLs | `[]` |
| `agent.target.argoHub.appSelector.allApps` | Select all applications | `false` |
| `agent.target.argoHub.appSelector.names` | List of application names | `[]` |
| `agent.target.argoHub.appSelector.labelSelector` | Label selector for applications | `{}` |

**For VCS (any environment type):**
| Parameter | Description | Default |
|-----------|-------------|---------|
| `agent.target.vcs.policies` | List of policy repositories | `[]` |
| `agent.target.vcs.resources` | List of resource repositories | `[]` |

## Examples

### Basic Agent Deployment

Deploy an Agent that scans the local cluster daily:

```bash
helm install remediator ./charts/go-nirmata-agent \
  --namespace nirmata \
  --create-namespace \
  --set agent.enabled=true \
  --set agent.prompt="Scan the cluster daily and report policy violations" \
  --set agent.environment.type=localCluster \
  --set agent.triggers[0].schedule.crontab="0 9 * * *"
```

### Agent with Email Notifications

Deploy an Agent that sends email reports:

```bash
helm install remediator ./charts/go-nirmata-agent \
  --namespace nirmata \
  --create-namespace \
  --set agent.enabled=true \
  --set agent.prompt="Scan ArgoCD apps and email security report to security-team@company.com" \
  --set agent.tools[0]=email \
  --set agent.environment.type=argoHub \
  --set agent.target.argoHub.appSelector.allApps=true \
  --set agent.triggers[0].schedule.crontab="0 */6 * * *"
```

### Agent with Values File

Create a `values-agent.yaml` file:

```yaml
agent:
  enabled: true
  name: production-scanner
  prompt: |
    Scan all production clusters for critical security violations.
    Generate remediation policies for any violations found.
    Send a detailed email report to security-team@company.com
  tools:
    - email
  environment:
    type: argoHub
  target:
    argoHub:
      appSelector:
        labelSelector:
          matchLabels:
            environment: production
  triggers:
    - schedule:
        crontab: "0 9 * * MON"  # Weekly on Monday at 9 AM
  llmConfigRef:
    name: bedrock-llm
```

Then install:

```bash
helm install remediator ./charts/go-nirmata-agent \
  --namespace nirmata \
  --create-namespace \
  -f values-agent.yaml
```

### Combined Deployment (Remediator + Agent)

Deploy both Remediator and Agent in one command:

```yaml
# values-full.yaml
llm:
  enabled: true
  provider: nirmataAI
  nirmataAI:
    model: "claude-3-5-sonnet-20241022"

tool:
  enabled: true
  name: github-tool

remediator:
  enabled: true
  name: auto-remediator
  environment:
    type: argoHub
  target:
    argoHub:
      appSelector:
        allApps: true
  remediation:
    schedule: "0 */6 * * *"
    actions:
      - type: CreatePR
        toolRefName: github-tool

agent:
  enabled: true
  name: security-auditor
  prompt: "Scan all clusters weekly and send security audit report"
  tools:
    - email
  environment:
    type: argoHub
  target:
    argoHub:
      appSelector:
        allApps: true
  triggers:
    - schedule:
        crontab: "0 9 * * MON"
```

```bash
helm install remediator ./charts/go-nirmata-agent \
  --namespace nirmata \
  --create-namespace \
  -f values-full.yaml
```

## Verification

After installation, verify your resources:

```bash
# Check controller pod
kubectl get pods -n nirmata

# Check LLMConfig
kubectl get llmconfig -n nirmata

# Check ToolConfig
kubectl get toolconfig -n nirmata

# Check Remediator (if enabled)
kubectl get remediator -n nirmata

# Check Agent (if enabled)
kubectl get agent -n nirmata

# View Agent status
kubectl describe agent <agent-name> -n nirmata
```

