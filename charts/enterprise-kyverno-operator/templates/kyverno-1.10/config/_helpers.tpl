{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.config.configMapName" -}}
    {{ default (include "kyverno110.fullname" .) .Values.kyverno.config.name }}
{{- end -}}

{{- define "kyverno110.config.metricsConfigMapName" -}}
    {{ default (printf "%s-metrics" (include "kyverno110.fullname" .)) .Values.kyverno.metricsConfig.name }}
{{- end -}}

{{- define "kyverno110.config.labels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.config.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno110.config.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "config")
) -}}
{{- end -}}

{{- define "kyverno110.config.imagePullSecret" -}}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .registry (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}
