{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.crds.labels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.crds.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno110.crds.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "crds")
) -}}
{{- end -}}
