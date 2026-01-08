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
Validate Nirmata authentication configuration
This template validates the authentication settings and fails early with clear error messages
*/}}
{{- define "go-nirmata-agent.validateNirmataAuth" -}}
{{- $authMethod := .Values.nirmata.auth | default "" -}}
{{- if not $authMethod -}}
{{- fail "nirmata.auth is required and must be set to either 'serviceAccountToken' or 'apiToken'" -}}
{{- end -}}
{{- if and (ne $authMethod "serviceAccountToken") (ne $authMethod "apiToken") -}}
{{- fail (printf "nirmata.auth must be either 'serviceAccountToken' or 'apiToken', got: '%s'" $authMethod) -}}
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