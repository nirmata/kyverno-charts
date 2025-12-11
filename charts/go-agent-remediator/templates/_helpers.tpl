{{/*
Expand the name of the chart.
*/}}
{{- define "go-agent-remediator.chartName" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Resource name (always remediator-agent)
*/}}
{{- define "go-agent-remediator.name" -}}
remediator-agent
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "go-agent-remediator.fullname" -}}
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
{{- define "go-agent-remediator.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "go-agent-remediator.labels" -}}
helm.sh/chart: {{ include "go-agent-remediator.chart" . }}
{{ include "go-agent-remediator.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "go-agent-remediator.selectorLabels" -}}
app.kubernetes.io/name: remediator-agent
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}



{{/*
Create the name of the service account to use
*/}}
{{- define "go-agent-remediator.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "go-agent-remediator.name" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Validate Nirmata authentication configuration
This template validates the authentication settings and fails early with clear error messages
*/}}
{{- define "go-agent-remediator.validateNirmataAuth" -}}
{{- $authMethod := .Values.nirmata.nirmataAuth | default "" -}}
{{- if not $authMethod -}}
{{- fail "nirmata.nirmataAuth is required and must be set to either 'serviceAccountToken' or 'apiToken'" -}}
{{- end -}}
{{- if and (ne $authMethod "serviceAccountToken") (ne $authMethod "apiToken") -}}
{{- fail (printf "nirmata.nirmataAuth must be either 'serviceAccountToken' or 'apiToken', got: '%s'" $authMethod) -}}
{{- end -}}
{{- if eq $authMethod "serviceAccountToken" -}}
{{- if not .Values.nirmata.serviceAccountTokenSecret -}}
{{- fail "nirmata.serviceAccountTokenSecret is required when nirmataAuth is 'serviceAccountToken'" -}}
{{- end -}}
{{- if not .Values.nirmata.serviceAccountTokenSecretNamespace -}}
{{- fail "nirmata.serviceAccountTokenSecretNamespace is required when nirmataAuth is 'serviceAccountToken'" -}}
{{- end -}}
{{- if not .Values.nirmata.serviceAccountTokenSecretKey -}}
{{- fail "nirmata.serviceAccountTokenSecretKey is required when nirmataAuth is 'serviceAccountToken'" -}}
{{- end -}}
{{- else if eq $authMethod "apiToken" -}}
{{- if not .Values.nirmata.apiTokenSecret -}}
{{- fail "nirmata.apiTokenSecret is required when nirmataAuth is 'apiToken'. Please provide the name of the Kubernetes secret containing your API token." -}}
{{- end -}}
{{- if not .Values.nirmata.apiTokenSecretNamespace -}}
{{- fail "nirmata.apiTokenSecretNamespace is required when nirmataAuth is 'apiToken'. Please provide the namespace where your API token secret is located." -}}
{{- end -}}
{{- end -}}
{{- end -}}