{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.labels.merge" -}}
{{- $labels := dict -}}
{{- range . -}}
  {{- $labels = merge $labels (fromYaml .) -}}
{{- end -}}
{{- with $labels -}}
  {{- toYaml $labels -}}
{{- end -}}
{{- end -}}

{{- define "kyverno.labels.component" -}}
app.kubernetes.io/component: {{ . }}
{{- end -}}