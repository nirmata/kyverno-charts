{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.name" -}}
{{- default "kyverno" .Values.kyverno.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "kyverno.fullname" -}}
{{- if .Values.kyverno.fullnameOverride -}}
  {{- .Values.kyverno.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- end -}}
{{- end -}}

{{- define "kyverno.chart" -}}
{{- printf "%s-%s" "kyverno-operator" .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}
