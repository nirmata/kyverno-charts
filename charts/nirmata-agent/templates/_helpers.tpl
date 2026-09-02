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
{{- if not .Values.nirmata.serviceAccountTokenSecret -}}
{{- fail "nirmata.serviceAccountTokenSecret is required when auth is 'serviceAccountToken'. Please provide the name of the Kubernetes secret containing your service account token in the same namespace as the deployment." -}}
{{- end -}}
{{- if not .Values.nirmata.serviceAccountTokenSecretKey -}}
{{- fail "nirmata.serviceAccountTokenSecretKey is required when auth is 'serviceAccountToken'" -}}
{{- end -}}
{{- else if eq $authMethod "apiToken" -}}
{{- if not .Values.nirmata.apiTokenSecret -}}
{{- fail "nirmata.apiTokenSecret is required when auth is 'apiToken'. Please provide the name of the Kubernetes secret containing your API token in the same namespace as the deployment." -}}
{{- end -}}
{{- if not .Values.nirmata.apiTokenSecretKey -}}
{{- fail "nirmata.apiTokenSecretKey is required when auth is 'apiToken'" -}}
{{- end -}}
{{- end -}}
{{- end -}}