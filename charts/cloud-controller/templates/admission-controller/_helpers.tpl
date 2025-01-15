{{/* vim: set filetype=mustache: */}}

{{- define "cloud-control.admission-controller.name" -}}
{{ template "cloud-control.name" . }}-admission-controller
{{- end -}}

{{- define "cloud-control.admission-controller.labels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.labels.common" .)
  (include "cloud-control.admission-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "cloud-control.admission-controller.matchLabels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.matchLabels.common" .)
  (include "cloud-control.labels.component" "admission-controller")
) -}}
{{- end -}}

{{- define "cloud-control.admission-controller.config.imagePullSecret" -}}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .registry (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}

{{- define "cloud-control.admission-controller.serviceAccountName" -}}
{{ default (include "cloud-control.admission-controller.name" .) .Values.admissionController.serviceAccount.name }}
{{- end -}}

{{- define "cloud-control.admission-controller.serviceName" -}}
{{- printf "%s-admission-controller-svc" (include "cloud-control.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}