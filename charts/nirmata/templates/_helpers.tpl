{{/* vim: set filetype=mustache: */}}

{{/* Expand the name of the chart. */}}
{{- define "kyverno.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "kyverno.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{/* Create chart name and version as used by the chart label. */}}
{{- define "kyverno.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/* Helm labels */}}
{{- define "kyverno.helmLabels" -}}
{{- if not .Values.templating.enabled -}}
helm.sh/chart: {{ template "kyverno.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}
{{- end -}}

{{/* Version labels */}}
{{- define "kyverno.versionLabels" -}}
{{- if .Values.templating.enabled -}}
app.kubernetes.io/version: {{ required "templating.version is required when templating.enabled is true" .Values.templating.version | replace "+" "_" }}
{{- else -}}
app.kubernetes.io/version: {{ .Chart.Version | replace "+" "_" }}
{{- end -}}
{{- end -}}

{{/* CRD labels */}}
{{- define "kyverno.crdLabels" -}}
app.kubernetes.io/component: kyverno
{{- with (include "kyverno.helmLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "kyverno.matchLabels" .) }}
{{ . }}
{{- end }}
app.kubernetes.io/part-of: {{ template "kyverno.name" . }}
{{- with (include "kyverno.versionLabels" .) }}
{{ . }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kyverno.labels" -}}
app.kubernetes.io/component: kyverno
{{- with (include "kyverno.helmLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "kyverno.matchLabels" .) }}
{{ . }}
{{- end }}
app.kubernetes.io/part-of: {{ template "kyverno.name" . }}
{{- with (include "kyverno.versionLabels" .) }}
{{ . }}
{{- end }}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kyverno.test-labels" -}}
{{- with (include "kyverno.helmLabels" .) }}
{{ . }}
{{- end }}
app: kyverno
app.kubernetes.io/component: kyverno
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ template "kyverno.name" . }}-test
app.kubernetes.io/part-of: {{ template "kyverno.name" . }}
app.kubernetes.io/version: "{{ .Chart.Version | replace "+" "_" }}"
{{- end -}}

{{/* matchLabels */}}
{{- define "kyverno.matchLabels" -}}
{{- if .Values.templating.enabled -}}
  {{- required "templating.version is required when templating.enabled is true" .Values.templating.version | replace "+" "_" -}}
{{- else -}}
  {{- .Chart.Version | replace "+" "_" -}}
{{- end -}}
{{- end -}}
