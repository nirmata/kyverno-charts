{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.cleanup-controller.name" -}}
{{ template "kyverno110.name" . }}-cleanup-controller
{{- end -}}

{{- define "kyverno110.cleanup-controller.labels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.cleanup-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno110.cleanup-controller.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "cleanup-controller")
) -}}
{{- end -}}

{{- define "kyverno110.cleanup-controller.image" -}}
{{- if .image.registry -}}
  {{ .image.registry }}/{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- else -}}
  {{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- end -}}
{{- end -}}

{{- define "kyverno110.cleanup-controller.roleName" -}}
{{ .Release.Name }}:cleanup-controller
{{- end -}}

{{- define "kyverno110.cleanup-controller.serviceAccountName" -}}
{{- if .Values.kyverno.cleanupController.rbac.create -}}
    {{ default (include "kyverno110.cleanup-controller.name" .) .Values.kyverno.cleanupController.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.kyverno.cleanupController.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}
