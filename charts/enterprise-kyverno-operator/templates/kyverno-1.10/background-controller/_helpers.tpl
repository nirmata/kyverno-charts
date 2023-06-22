{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.background-controller.name" -}}
{{ template "kyverno110.name" . }}-background-controller
{{- end -}}

{{- define "kyverno110.background-controller.labels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.background-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno110.background-controller.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "background-controller")
) -}}
{{- end -}}

{{- define "kyverno110.background-controller.image" -}}
{{- if .image.registry -}}
  {{ .image.registry }}/{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- else -}}
  {{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- end -}}
{{- end -}}

{{- define "kyverno110.background-controller.roleName" -}}
{{ .Release.Name }}:background-controller
{{- end -}}

{{- define "kyverno110.background-controller.serviceAccountName" -}}
{{- if .Values.kyverno.backgroundController.rbac.create -}}
    {{ default (include "kyverno110.background-controller.name" .) .Values.kyverno.backgroundController.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.kyverno.backgroundController.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}
