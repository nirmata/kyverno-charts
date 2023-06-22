{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.name" -}}
{{- default "kyverno" .Values.kyverno.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kyverno110.fullname" -}}
{{- if .Values.kyverno.fullnameOverride -}}
  {{- .Values.kyverno.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
  {{- $name := default "kyverno" .Values.kyverno.nameOverride -}}
  {{- if contains $name .Release.Name -}}
    {{- .Release.Name | trunc 63 | trimSuffix "-" -}}
  {{- else -}}
    {{- printf "%s-%s" "kyverno" $name | trunc 63 | trimSuffix "-" -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{- define "kyverno110.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
