{{/* vim: set filetype=mustache: */}}

{{- define "cloud-control.events-controller.name" -}}
{{ template "cloud-control.name" . }}-events-controller
{{- end -}}

{{- define "cloud-control.events-controller.labels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.labels.common" .)
  (include "cloud-control.events-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "cloud-control.events-controller.matchLabels" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.matchLabels.common" .)
  (include "cloud-control.labels.component" "events-controller")
) -}}
{{- end -}}

{{/* Note: imagePullSecret helper might be global or defined elsewhere, keeping structure for now */}}
{{- define "cloud-control.events-controller.config.imagePullSecret" -}}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .registry (printf "%s:%s" .username .password | b64enc) | b64enc }}
{{- end -}}

{{- define "cloud-control.events-controller.serviceAccountName" -}}
{{ default (include "cloud-control.events-controller.name" .) .Values.eventsController.serviceAccount.name }}
{{- end -}} 

{{- define "cloud-control.events-controller.serviceName" -}}
{{- printf "%s-events-controller-svc" (include "cloud-control.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}