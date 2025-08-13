{{/* vim: set filetype=mustache: */}}
{{- define "kyverno.config.labels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.labels.common" .)
  (include "kyverno.config.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno.config.matchLabels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.matchLabels.common" .)
  (include "kyverno.labels.component" "config")
) -}}
{{- end -}}

{{- define "kyverno.config.webhooks" -}}
{{- $excludeDefault := dict "key" "kubernetes.io/metadata.name" "operator" "NotIn" "values" (list (include "kyverno.namespace" .)) }}
{{- $newWebhook := list }}
{{- range $webhook := .Values.kyverno.config.webhooks }}
  {{- $namespaceSelector := default dict $webhook.namespaceSelector }}
  {{- $matchExpressions := default list $namespaceSelector.matchExpressions }}
  {{- $newNamespaceSelector := dict "matchLabels" $namespaceSelector.matchLabels "matchExpressions" (append $matchExpressions $excludeDefault) }}
  {{- $newWebhook = append $newWebhook (merge (omit $webhook "namespaceSelector") (dict "namespaceSelector" $newNamespaceSelector)) }}
{{- end }}
{{- $newWebhook | toJson }}
{{- end -}}
