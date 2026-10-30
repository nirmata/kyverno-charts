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
| `logging.format` | Log output format: `text` (human-readable) or `json` (one JSON object per line, klog included) | `text` |
| `tracing.enabled` | Export OpenTelemetry traces over OTLP gRPC (also enabled when `OTEL_EXPORTER_OTLP_ENDPOINT` is set) | `false` |
| `tracing.endpoint` | OTLP gRPC endpoint, set as `OTEL_EXPORTER_OTLP_ENDPOINT` (empty: exporter default `localhost:4317`) | `""` |
| `tracing.insecure` | Connect to the endpoint without TLS (`OTEL_EXPORTER_OTLP_INSECURE=true`) | `false` |
| `tracing.serviceName` | `service.name` resource attribute (`OTEL_SERVICE_NAME`); empty uses `go-nirmata-agent` | `""` |

*Note: Image tag is automatically set to `Chart.yaml` appVersion*

### LLM Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `llm.enabled` | Enable creation of LLMConfig resource | `true` |
| `llm.provider` | LLM provider (nirmataAI, bedrock, azure-openai, anthropic) | `nirmataAI` |
| `llm.nirmataAI.model` | Model name for Nirmata AI | `""` |
| `llm.bedrock.model` | AWS Bedrock model name | `""` |
| `llm.bedrock.region` | AWS region | `""` |
| `llm.bedrock.secretRef.name` | Secret containing AWS credentials | `""` |
| `llm.bedrock.accessKeyId` / `secretAccessKey` / `sessionToken` | Inline AWS credentials; the chart creates the Secret (see [Inline credentials](#inline-credentials-single-command-install)) | `""` |
| `llm.azureOpenAI.endpoint` | Azure OpenAI endpoint | `""` |
| `llm.azureOpenAI.deploymentName` | Azure deployment name | `""` |
| `llm.azureOpenAI.secretRef.name` | Secret containing API key | `""` |
| `llm.azureOpenAI.apiKey` | Inline Azure OpenAI API key; the chart creates the Secret | `""` |
| `llm.anthropic.model` | Anthropic model ID, e.g. `claude-opus-5` (required) | `""` |
| `llm.anthropic.baseURL` | Override the Anthropic endpoint, e.g. an internal gateway. Include the scheme. Empty uses `https://api.anthropic.com` | `""` |
| `llm.anthropic.secretRef.name` | Secret containing the Anthropic API key | `""` |
| `llm.anthropic.secretRef.key` | Key within that secret | `api-key` |
| `llm.anthropic.apiKey` | Inline Anthropic API key; the chart creates the Secret | `""` |

#### Direct Anthropic API

Use this when the API key is yours and you do not want Bedrock or Azure in the
path. `baseURL` points the agent at an internal gateway, so no traffic needs to
reach `api.anthropic.com` directly.

```bash
kubectl create secret generic anthropic-api-key -n nirmata \
  --from-literal=api-key='<YOUR_ANTHROPIC_API_KEY>'
```

```yaml
llm:
  enabled: true
  provider: anthropic
  anthropic:
    model: claude-opus-5
    # Omit to use https://api.anthropic.com
    baseURL: https://ai-gateway.internal
    secretRef:
      name: anthropic-api-key
      key: api-key
```

The secret must exist before the agent reads it, and the key is loaded when the
LLM client is constructed rather than watched. After rotating the key, restart
the agent:

```bash
kubectl rollout restart deploy/<release>-nirmata-agent -n nirmata
```

Verify:

```bash
kubectl get llmconfig -n nirmata -o yaml    # spec.type should be "anthropic"
kubectl logs -n nirmata deploy/<release>-nirmata-agent | grep -i "LLM client"
# expect: Created LLM client for provider anthropic with model claude-opus-5
```

### Tool Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tool.enabled` | Enable creation of ToolConfig resource | `true` |
| `tool.name` | ToolConfig name. Empty defaults to `nirmata-agent-<tool.type>` (`nirmata-agent-github` / `nirmata-agent-gitlab`) | `github-tool` |
| `tool.type` | Git provider (`github`, `gitlab`, `azure-devops`, or `bitbucket`; `azure-devops` and `bitbucket` require `tool.credentials.method: pat`, and `bitbucket` also requires `tool.credentials.pat.usernameSecret`) | `github` |
| `tool.baseURL` | API base URL of a self-hosted GitLab served under a path prefix or on a different host than the repos, or the Azure DevOps organization/collection URL (`gitlab` and `azure-devops` only). Empty derives it from each repository URL | `""` |
| `tool.tls.caBundleSecretRef.name` | Secret (release namespace) holding a PEM CA bundle to trust for git clone and API calls | `""` |
| `tool.tls.caBundleSecretRef.key` | Key within that Secret | `ca.crt` |
| `tool.tls.insecureSkipVerify` | Disable TLS verification entirely (not for production) | `false` |
| `tool.defaults.git.pullRequests.systemLabels` | PR labels computed per PR (`branch`, `clusterName`, `appName`, `namespace`, `remediatorName`). Unset applies `remediatorName`, `clusterName`, `namespace`, `branch`; `[]` disables them | unset |
| `tool.credentials.method` | Auth method (`nirmata-app`, `app` or `pat`; `app` is GitHub only) | `nirmata-app` |
| `tool.credentials.pat.secret.name` | Secret containing the GitHub PAT, GitLab/Azure DevOps access token, or Bitbucket app-password | `github-token` |
| `tool.credentials.pat.usernameSecret.name` / `.key` | Bitbucket only (required): Secret and key holding the REST API username (account email on Atlassian-managed accounts) | unset |
| `tool.credentials.pat.gitUsernameSecret.name` / `.key` | Bitbucket only (optional): Secret and key holding the account username used for git HTTPS clone; defaults to `usernameSecret` | unset |
| `tool.credentials.pat.token` | Inline GitHub PAT, GitLab/Azure DevOps access token, or Bitbucket app-password; the chart creates the Secret | `""` |
| `tool.credentials.app.appId` | GitHub App ID | `""` |
| `tool.credentials.app.privateKey` | Inline PEM private key (pass with `--set-file`); the chart creates the Secret | `""` |

### Inline credentials (single-command install)

Every credential can be referenced from an existing Secret (the default) or
supplied inline, in which case the chart creates the Secret and points the
Deployment, ToolConfig or LLMConfig at it. Nothing is created while the inline
values are empty, and a Secret renders only when the component that uses it is
selected (`nirmata.auth`, `tool.credentials.method`, `llm.provider`).

| Inline value | Used when | Generated Secret (name / key) |
|--------------|-----------|-------------------------------|
| `nirmata.serviceAccountToken` | `nirmata.auth=serviceAccountToken` | `nirmata.serviceAccountTokenSecret` (`nirmata-service-account-token`) / `nirmata.serviceAccountTokenSecretKey` |
| `nirmata.apiToken` | `nirmata.auth=apiToken` | `nirmata.apiTokenSecret` or `nirmata-api-token` / `nirmata.apiTokenSecretKey` |
| `tool.credentials.pat.token` | `tool.credentials.method=pat` | `pat.secret.name` or `nirmata-agent-git-token` / `pat.secret.key` or `token` |
| `tool.credentials.app.privateKey` | `tool.credentials.method=app` | `app.privateKeySecret.name` or `nirmata-agent-github-app` / `app.privateKeySecret.key` or `private-key.pem` |
| `llm.bedrock.accessKeyId` + `secretAccessKey` (+ `sessionToken`) | `llm.provider=bedrock` | `bedrock.secretRef.name` or `nirmata-agent-bedrock-credentials` / `aws_access_key_id`, `aws_secret_access_key`, `aws_session_token` |
| `llm.azureOpenAI.apiKey` | `llm.provider=azure-openai` | `azureOpenAI.secretRef.name` or `nirmata-agent-azure-openai` / `azureOpenAI.secretRef.key` |
| `llm.anthropic.apiKey` | `llm.provider=anthropic` | `anthropic.secretRef.name` or `nirmata-agent-anthropic` / `anthropic.secretRef.key` |

```bash
helm install nirmata-agent ./charts/go-nirmata-agent -n nirmata --create-namespace \
  --set nirmata.serviceAccountToken="$NIRMATA_TOKEN" \
  --set tool.credentials.method=app \
  --set tool.credentials.app.appId="$GITHUB_APP_ID" \
  --set-file tool.credentials.app.privateKey=./private-key.pem
```

**Security:** inline values are stored in the Helm release Secret and can end up
in shell history or values files. For production prefer pre-created Secrets or an
external secret manager (External Secrets Operator, Sealed Secrets, Vault), and
never commit inline values to a values file. Generated Secrets are removed on
`helm uninstall`. Installing a generated Secret whose name already exists (for
example a manually created `nirmata-service-account-token`) fails until the
existing Secret is deleted or a different name is set.

### Remediator Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `remediator.enabled` | Enable creation of Remediator resource | `false` |
| `remediator.name` | Remediator resource name | `nirmata-agent` |
| `remediator.environment.type` | Environment type (`localCluster`, `argoHub`, or `fluxHub`) | `argoHub` |
| `remediator.remediation.remediationMode` | `ai` (LLM-generated fixes) or `prescriptive` (deterministic resource right-sizing, no LLM) | `ai` |
| `remediator.remediation.llmConfigRef.name` | LLMConfig used in `ai` mode; not rendered in `prescriptive` mode | `<release-name>-llm` |
| `remediator.remediation.llmConfigRef.namespace` | Namespace of that LLMConfig | release namespace |
| `remediator.remediation.resourceOptimization.policyCategories` | `prescriptive` only: `policies.kyverno.io/category` values that are in scope | CRD default (`["Resource Management"]`) |
| `remediator.remediation.schedule` | Cron schedule for remediation | `0 */6 * * *` |
| `remediator.remediation.eventPolling.enabled` | Enable PR event polling | `true` |
| `remediator.remediation.eventPolling.allowedUsers` | Git usernames allowed to run `@nirmatabot` PR comment commands (case-insensitive). Empty allows every commenter and logs a warning | `[]` |
| `remediator.remediation.actions` | List of remediation actions. `toolRefName` defaults to the chart's ToolConfig | `[{type: CreatePR}]` |

#### Prescriptive mode (no LLM)

`remediationMode: prescriptive` right-sizes container resources from VPA
recommendations and policy bounds without calling an LLM, so no LLMConfig is
needed and `llmConfigRef` is omitted from the rendered Remediator. Set
`llm.enabled=false` to skip the LLMConfig entirely. A self-hosted GitLab with a
private CA is supported through `tool.tls`. This example runs standalone, without
Nirmata Control Hub credentials (`nirmata.auth: none`):

```yaml
nirmata:
  auth: none

llm:
  enabled: false

tool:
  enabled: true
  name: ""            # -> nirmata-agent-gitlab
  type: gitlab
  baseURL: ""         # only when GitLab is served under a path prefix
  tls:
    caBundleSecretRef:
      name: gitlab-ca  # Secret in the release namespace, key ca.crt
  credentials:
    method: pat
    pat:
      secret:
        name: gitlab-token
        key: token

remediator:
  enabled: true
  environment:
    type: fluxHub
  target:
    fluxHub:
      kustomizationSelector:
        allKustomizations: true
  remediation:
    remediationMode: prescriptive
    resourceOptimization:
      policyCategories:
        - "Resource Optimization"
    actions:
      - type: CreatePR
```

#### Remediator Target Configuration

**For FluxHub** (required when `remediator.environment.type` is `fluxHub`):

| Parameter | Description | Default |
|-----------|-------------|---------|
| `remediator.target.fluxHub.fluxNamespace` | Namespace where Flux controllers are installed | `flux-system` |
| `remediator.target.fluxHub.kustomizationSelector.names` | Kustomization names to target | `[]` |
| `remediator.target.fluxHub.kustomizationSelector.namespaces` | Hub namespaces to search | `[]` |
| `remediator.target.fluxHub.kustomizationSelector.labelSelector` | Label selector for Kustomizations | `{}` |
| `remediator.target.fluxHub.kustomizationSelector.allKustomizations` | Select all Kustomizations in searched namespaces | `false` |
| `remediator.target.fluxHub.helmReleaseSelector.names` | HelmRelease names to target | `[]` |
| `remediator.target.fluxHub.helmReleaseSelector.namespaces` | Hub namespaces to search | `[]` |
| `remediator.target.fluxHub.helmReleaseSelector.labelSelector` | Label selector for HelmReleases | `{}` |
| `remediator.target.fluxHub.helmReleaseSelector.allHelmReleases` | Select all HelmReleases in searched namespaces | `false` |

At least one of `kustomizationSelector` or `helmReleaseSelector` must be set; both
may be set to remediate Kustomizations and HelmReleases together. In hub-spoke
setups each spoke typically has a dedicated namespace on the hub, so
`namespaces` is the usual way to scope a selector.

### Agent Configuration

The Agent resource enables autonomous AI-powered operations on your Kubernetes clusters.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `agent.enabled` | Enable creation of Agent resource | `false` |
| `agent.name` | Agent resource name | `<release-name>-agent` |
| `agent.prompt` | **REQUIRED** - Custom instruction defining agent behavior (min 10 chars) | `""` |
| `agent.tools` | List of additional tool names (email, send_slack_message, etc.) | `[]` |
| `agent.environment.type` | Environment type (`localCluster` or `argoHub`; `fluxHub` is not yet renderable by this chart) | `localCluster` |
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


## Chart tests (contributors)

Each `ci/*-values.yaml` file is a values scenario. `make helm-test` runs `helm lint` and
`helm template` for every scenario, compares the output with the goldens in
`hack/charttest/testdata/`, and validates them with kubeconform against the Kubernetes
schemas and the repo CRDs. After an intended template change, regenerate and review the
goldens with `go test ./hack/charttest/ -update`. A new scenario only needs a new
`ci/<name>-values.yaml` plus `-update`.
