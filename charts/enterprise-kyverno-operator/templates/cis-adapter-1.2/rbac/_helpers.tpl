{{/*
Expand the name of the chart.
*/}}
{{- define "kube-bench.name" -}}
{{- default "cis-adapter" .Values.cisAdapter.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kube-bench.fullname" -}}
{{- if .Values.cisAdapter.fullnameOverride }}
{{- .Values.cisAdapter.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default "cis-adapter" .Values.cisAdapter.nameOverride }}
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
{{- define "kube-bench.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "kube-bench.labels" -}}
app.kubernetes.io/instance: nirmata
app.kubernetes.io/name: nirmata
helm.sh/chart: {{ include "kube-bench.chart" . }}
{{ include "kube-bench.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/* matchLabels */}}
{{- define "kube-bench.matchLabels" -}}
app.kubernetes.io/name: nirmata
app.kubernetes.io/instance: nirmata
{{- end -}}

{{/*
Selector labels
*/}}
{{- define "kube-bench.selectorLabels" -}}
app.kubernetes.io/name: {{ include "kube-bench.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "kube-bench.serviceAccountName" -}}
{{- if .Values.cisAdapter.serviceAccount.create }}
{{- default (include "kube-bench.fullname" .) .Values.cisAdapter.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.cisAdapter.serviceAccount.name }}
{{- end }}
{{- end }}
