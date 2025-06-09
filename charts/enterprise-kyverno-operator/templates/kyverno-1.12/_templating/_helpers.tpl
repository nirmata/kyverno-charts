{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.templating.labels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.labels.common" .)
  (include "kyverno.matchLabels.common" .)
) -}}
{{- end -}}

{{- define "kyverno.annotations.common" -}}
{{- if .Values.customAnnotations }}
  {{- template "kyverno.annotations.merge" (list
    (toYaml .Values.customAnnotations)
  ) -}}
  {{- end }}
{{- end -}}
