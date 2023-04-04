{{/*
Expand the name of the chart.
*/}}
{{- define "kyverno-aws-adapter.name" -}}
{{- default "kyverno-aws-adapter" .Values.awsAdapter.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kyverno-aws-adapter.fullname" -}}
{{- if .Values.awsAdapter.fullnameOverride }}
{{- .Values.awsAdapter.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "kyverno-aws-adapter" .Values.awsAdapter.nameOverride }}
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
{{- define "kyverno-aws-adapter.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/* Create the name of the service account to use */}}
{{- define "kyverno-aws-adapter.serviceAccountName" -}}
{{- if .Values.awsAdapter.rbac.create -}}
    {{ default (include "kyverno-aws-adapter.fullname" .) .Values.awsAdapter.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.awsAdapter.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Common labels
*/}}
{{- define "kyverno-aws-adapter.labels" -}}
helm.sh/chart: {{ include "kyverno-aws-adapter.chart" . }}
{{ include "kyverno-aws-adapter.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "kyverno-aws-adapter.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kyverno-aws-adapter.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "kyverno-aws-adapter.image" -}}
{{ printf "%s:%s" (required "An image repository is required" .Values.awsAdapter.image.repository) (default .Chart.AppVersion .Values.awsAdapter.image.tag) }}
{{- end }}
