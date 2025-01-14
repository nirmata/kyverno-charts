{{/* vim: set filetype=mustache: */}}

{{- define "cloud-control.reportsController.name" -}}
{{ template "cloud-control.name" . }}-reports-controller
{{- end -}}

{{- define "cloud-control.reportsController.labels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.labels.common" .)
  (include "cloud-control.reportsController.matchLabels" .)
) -}}
{{- end -}}

{{- define "cloud-control.reportsController.matchLabels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.matchLabels.common" .)
  (include "cloud-control.labels.component" "reportsController")
) -}}
{{- end -}}

{{- define "cloud-control.reportsController.config.imagePullSecret" -}}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .registry (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}

{{- define "cloud-control.reportsController.serviceAccountName" -}}
{{ default (include "cloud-control.reportsController.name" .) .Values.reportsController.serviceAccount.name }}
{{- end -}}
