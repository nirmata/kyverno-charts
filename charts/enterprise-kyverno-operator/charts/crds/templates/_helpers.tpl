{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.crds.labels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.crds.matchLabels" .)
  (toYaml .Values.customLabels)
) -}}
{{- end -}}

{{- define "kyverno.crds.matchLabels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.labels.component" "crds")
) -}}
{{- end -}}
