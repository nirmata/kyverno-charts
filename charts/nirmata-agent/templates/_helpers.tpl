{{/*
Expand the name of the chart.
*/}}
{{- define "go-nirmata-agent.chartName" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resource name (always nirmata-agent)
*/}}
{{- define "go-nirmata-agent.name" -}}
nirmata-agent
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "go-nirmata-agent.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "go-nirmata-agent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "go-nirmata-agent.labels" -}}
helm.sh/chart: {{ include "go-nirmata-agent.chart" . }}
{{ include "go-nirmata-agent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "go-nirmata-agent.selectorLabels" -}}
app.kubernetes.io/name: nirmata-agent
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use
*/}}
{{- define "go-nirmata-agent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "go-nirmata-agent.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
ToolConfig name. When tool.name is empty it defaults to <name>-<tool.type>, so
the historical "nirmata-agent-github" default is preserved for GitHub while
other providers (gitlab) get a matching, provider-neutral suffix.
*/}}
{{- define "go-nirmata-agent.toolName" -}}
{{- .Values.tool.name | default (printf "%s-%s" (include "go-nirmata-agent.name" .) (.Values.tool.type | default "github")) }}
{{- end }}

{{/*
Remediation mode of the Remediator CR ("ai" or "prescriptive"); defaults to "ai"
to match the CRD default.
*/}}
{{- define "go-nirmata-agent.remediationMode" -}}
{{- ((.Values.remediator | default dict).remediation | default dict).remediationMode | default "ai" }}
{{- end }}

{{/*
Report whether Nirmata platform credentials are configured.
An empty nirmata.auth (or "none") means the agent runs without them, which is
supported when the LLM provider and GitHub credentials are supplied by the user.
*/}}
{{- define "go-nirmata-agent.nirmataAuthEnabled" -}}
{{- $authMethod := .Values.nirmata.auth | default "" -}}
{{- if and $authMethod (ne $authMethod "none") -}}true{{- end -}}
{{- end -}}

{{/*
Validate Nirmata authentication configuration
This template validates the authentication settings and fails early with clear error messages
*/}}
{{- define "go-nirmata-agent.validateNirmataAuth" -}}
{{- $authMethod := .Values.nirmata.auth | default "" -}}
{{- if not (include "go-nirmata-agent.nirmataAuthEnabled" .) -}}
{{- /* No Nirmata credentials. Fail if a feature that requires them is enabled,
       so the conflict surfaces at install time rather than at runtime. */ -}}
{{- if and .Values.llm.enabled (eq .Values.llm.provider "nirmataAI") -}}
{{- fail "llm.provider 'nirmataAI' requires Nirmata credentials, but nirmata.auth is not set. Either set nirmata.auth to 'serviceAccountToken' or 'apiToken', or choose a different llm.provider (bedrock, azure-openai, anthropic)." -}}
{{- end -}}
{{- if and .Values.tool.enabled (eq .Values.tool.credentials.method "nirmata-app") -}}
{{- fail "tool.credentials.method 'nirmata-app' requires Nirmata credentials, but nirmata.auth is not set. Either set nirmata.auth to 'serviceAccountToken' or 'apiToken', or use tool.credentials.method 'pat' or 'app' with your own GitHub credentials." -}}
{{- end -}}
{{- else if and (ne $authMethod "serviceAccountToken") (ne $authMethod "apiToken") -}}
{{- fail (printf "nirmata.auth must be 'serviceAccountToken', 'apiToken', or 'none', got: '%s'" $authMethod) -}}
{{- end -}}
{{- if eq $authMethod "serviceAccountToken" -}}
{{- if not (include "go-nirmata-agent.serviceAccountTokenSecretName" .) -}}
{{- fail "nirmata.serviceAccountTokenSecret (or an inline nirmata.serviceAccountToken) is required when auth is 'serviceAccountToken'. Please provide the name of the Kubernetes secret containing your service account token in the same namespace as the deployment." -}}
{{- end -}}
{{- if not .Values.nirmata.serviceAccountTokenSecretKey -}}
{{- fail "nirmata.serviceAccountTokenSecretKey is required when auth is 'serviceAccountToken'" -}}
{{- end -}}
{{- else if eq $authMethod "apiToken" -}}
{{- if not (include "go-nirmata-agent.apiTokenSecretName" .) -}}
{{- fail "nirmata.apiTokenSecret (or an inline nirmata.apiToken) is required when auth is 'apiToken'. Please provide the name of the Kubernetes secret containing your API token in the same namespace as the deployment." -}}
{{- end -}}
{{- if not .Values.nirmata.apiTokenSecretKey -}}
{{- fail "nirmata.apiTokenSecretKey is required when auth is 'apiToken'" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/*
Inline credentials (opt-in, see templates/secrets.yaml). Each "...SecretName"
helper returns the Secret a consumer (Deployment env, ToolConfig, LLMConfig)
references: the user-supplied secret name when set, otherwise the name of the
Secret generated from the inline value, otherwise "". Without inline values the
result equals the existing secret-name value, so existing installs render
unchanged.
*/}}
{{- define "go-nirmata-agent.serviceAccountTokenSecretName" -}}
{{- if .Values.nirmata.serviceAccountTokenSecret -}}
{{- .Values.nirmata.serviceAccountTokenSecret -}}
{{- else if .Values.nirmata.serviceAccountToken -}}
nirmata-service-account-token
{{- end -}}
{{- end -}}

{{- define "go-nirmata-agent.apiTokenSecretName" -}}
{{- if .Values.nirmata.apiTokenSecret -}}
{{- .Values.nirmata.apiTokenSecret -}}
{{- else if .Values.nirmata.apiToken -}}
nirmata-api-token
{{- end -}}
{{- end -}}

{{- define "go-nirmata-agent.patSecretName" -}}
{{- $pat := .Values.tool.credentials.pat | default dict -}}
{{- $ref := $pat.secret | default dict -}}
{{- if $ref.name -}}
{{- $ref.name -}}
{{- else if $pat.token -}}
{{- include "go-nirmata-agent.name" . }}-git-token
{{- end -}}
{{- end -}}

{{- define "go-nirmata-agent.patSecretKey" -}}
{{- $pat := .Values.tool.credentials.pat | default dict -}}
{{- ($pat.secret | default dict).key | default "token" -}}
{{- end -}}

{{- define "go-nirmata-agent.appPrivateKeySecretName" -}}
{{- $app := .Values.tool.credentials.app | default dict -}}
{{- $ref := $app.privateKeySecret | default dict -}}
{{- if $ref.name -}}
{{- $ref.name -}}
{{- else if $app.privateKey -}}
{{- include "go-nirmata-agent.name" . }}-github-app
{{- end -}}
{{- end -}}

{{- define "go-nirmata-agent.appPrivateKeySecretKey" -}}
{{- $app := .Values.tool.credentials.app | default dict -}}
{{- ($app.privateKeySecret | default dict).key | default "private-key.pem" -}}
{{- end -}}

{{- define "go-nirmata-agent.bedrockSecretName" -}}
{{- $b := .Values.llm.bedrock | default dict -}}
{{- $ref := $b.secretRef | default dict -}}
{{- if $ref.name -}}
{{- $ref.name -}}
{{- else if or $b.accessKeyId $b.secretAccessKey -}}
{{- include "go-nirmata-agent.name" . }}-bedrock-credentials
{{- end -}}
{{- end -}}

{{- define "go-nirmata-agent.azureOpenAISecretName" -}}
{{- $a := .Values.llm.azureOpenAI | default dict -}}
{{- $ref := $a.secretRef | default dict -}}
{{- if $ref.name -}}
{{- $ref.name -}}
{{- else if $a.apiKey -}}
{{- include "go-nirmata-agent.name" . }}-azure-openai
{{- end -}}
{{- end -}}

{{- define "go-nirmata-agent.anthropicSecretName" -}}
{{- $a := .Values.llm.anthropic | default dict -}}
{{- $ref := $a.secretRef | default dict -}}
{{- if $ref.name -}}
{{- $ref.name -}}
{{- else if $a.apiKey -}}
{{- include "go-nirmata-agent.name" . }}-anthropic
{{- end -}}
{{- end -}}