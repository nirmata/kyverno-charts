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


### Git provider (`tool`)

Selects where the agent opens pull requests.

| Parameter | Description | Default |
|-----------|-------------|---------|
| `tool.type` | Git provider: `github`, `gitlab`, or `azure-devops` | `github` |
| `tool.name` | ToolConfig name. Defaults to `<release>-<tool.type>` when unset | `github-tool` |
| `tool.baseURL` | API endpoint override for self-hosted servers (GitHub Enterprise, self-managed GitLab, Azure DevOps Server) | `""` |
| `tool.credentials.method` | `pat`, `app`, or `nirmata-app`. `azure-devops` supports `pat` only | `pat` |

> `tool.type` is unrelated to `llm.provider: azure-openai`, which only selects an
> LLM backend. `tool.type` controls where the agent pushes code.

Invalid combinations are rejected by `helm install` rather than at apply time.

### Azure Repos (Azure DevOps)

Create a PAT with the **Code (read & write)** scope — add **Pull Request Threads
(read & write)** if the agent should also post PR comments — and store it in a
secret:

```bash
kubectl create secret generic azure-devops-pat \
  --from-literal=token=<PAT> -n <namespace>
```

```yaml
tool:
  enabled: true
  name: azure-tool
  type: azure-devops
  credentials:
    method: pat
    pat:
      secret:
        name: azure-devops-pat
        key: token
  defaults:
    git:
      pullRequests:
        branchPrefix: remediation-

remediator:
  remediation:
    actions:
      - type: CreatePR
        toolRefName: azure-tool
```

Repository URLs may use any Azure Repos form; the organization and project are
derived from the URL, so no extra configuration is needed:

```
https://dev.azure.com/{org}/{project}/_git/{repo}
https://{org}.visualstudio.com/{project}/_git/{repo}
```

For **Azure DevOps Server** (on-premises), set `tool.baseURL` to the collection URL
if the API endpoint differs from the repository URL host:

```yaml
tool:
  type: azure-devops
  baseURL: https://tfs.corp.example.com/DefaultCollection
```

If the server uses a private CA, supply it via `spec.tls.caBundleSecretRef` on the
ToolConfig.

#### Azure Repos limitations

| Feature | Status |
|---|---|
| Create / update pull requests | Supported |
| PR labels (Azure "tags") | Supported |
| PR comments, `@nirmatabot` replies | Supported |
| CI status checks on PRs | Not supported — GitHub only |
| `CreateIssue` action | Not supported — Azure tracks issues as Work Items |
| GitHub App / Entra ID auth | Not supported — PAT only |
