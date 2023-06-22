{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.chartVersion" -}}
{{- .Chart.Version | replace "+" "_" -}}
{{- end -}}
