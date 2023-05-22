{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.reports-controller.name" -}}
{{ template "kyverno110.name" . }}-reports-controller
{{- end -}}

{{- define "kyverno110.reports-controller.labels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.reports-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno110.reports-controller.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "reports-controller")
) -}}
{{- end -}}

{{- define "kyverno110.reports-controller.image" -}}
{{- if .image.registry -}}
  {{ .image.registry }}/{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- else -}}
  {{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- end -}}
{{- end -}}

{{- define "kyverno110.reports-controller.roleName" -}}
{{ .Release.Name }}:reports-controller
{{- end -}}

{{- define "kyverno110.reports-controller.serviceAccountName" -}}
{{- if .Values.kyverno.reportsController.rbac.create -}}
    {{ default (include "kyverno110.reports-controller.name" .) .Values.kyverno.reportsController.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.kyverno.reportsController.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}
