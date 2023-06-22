{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.admission-controller.name" -}}
{{ template "kyverno110.name" . }}-admission-controller
{{- end -}}

{{- define "kyverno110.admission-controller.labels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.admission-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno110.admission-controller.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "admission-controller")
) -}}
{{- end -}}

{{- define "kyverno110.admission-controller.roleName" -}}
{{ .Release.Name }}:admission-controller
{{- end -}}

{{- define "kyverno110.admission-controller.serviceAccountName" -}}
{{- if .Values.kyverno.admissionController.rbac.create -}}
    {{ default (include "kyverno110.admission-controller.name" .) .Values.kyverno.admissionController.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.kyverno.admissionController.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "kyverno110.admission-controller.serviceName" -}}
{{- printf "%s-svc" (include "kyverno110.fullname" .) | trunc 63 | trimSuffix "-" -}}
{{- end -}}
