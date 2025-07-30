{{/* vim: set filetype=mustache: */}}

{{- define "cloud-control.scanner.name" -}}
{{ template "cloud-control.name" . }}-scanner
{{- end -}}

{{- define "cloud-control.scanner.labels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.labels.common" .)
  (include "cloud-control.scanner.matchLabels" .)
) -}}
{{- end -}}

{{- define "cloud-control.scanner.matchLabels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.matchLabels.common" .)
  (include "cloud-control.labels.component" "scanner")
) -}}
{{- end -}}

{{- define "cloud-control.scanner.config.imagePullSecret" -}}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .registry (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}

{{- define "cloud-control.scanner.serviceAccountName" -}}
{{ default (include "cloud-control.scanner.name" .) .Values.scanner.serviceAccount.name }}
{{- end -}}
