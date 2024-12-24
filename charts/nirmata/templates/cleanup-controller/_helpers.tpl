{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.cleanup-controller.name" -}}
{{ template "kyverno.name" . }}-cleanup-controller
{{- end -}}

{{- define "kyverno.cleanup-controller.labels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.labels.common" .)
  (include "kyverno.cleanup-controller.matchLabels" .)
) -}}
{{- end -}}

{{- define "kyverno.cleanup-controller.matchLabels" -}}
{{- template "kyverno.labels.merge" (list
  (include "kyverno.matchLabels.common" .)
  (include "kyverno.labels.component" "cleanup-controller")
) -}}
{{- end -}}

{{- define "kyverno.cleanup-controller.image" -}}
{{- $imageRegistry := default .image.registry .globalRegistry -}}
{{- $fipsEnabled := .fipsEnabled -}}
{{- if $imageRegistry -}}
    {{- if $fipsEnabled -}}
      {{ .image.registry }}/{{ required "An image repository is required" .image.repository }}-fips:non-rootuser-fix
    {{- else -}}
      {{ $imageRegistry }}/{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
    {{- end -}}
{{- else -}}
  {{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- end -}}
{{- end -}}

{{- define "kyverno.cleanup-controller.roleName" -}}
{{ include "kyverno.fullname" . }}:cleanup-controller
{{- end -}}

{{- define "kyverno.cleanup-controller.serviceAccountName" -}}
{{- if .Values.cleanupController.rbac.create -}}
    {{ default (include "kyverno.cleanup-controller.name" .) .Values.cleanupController.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.cleanupController.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "kyverno.cleanup-controller.serviceAnnotations" -}}
  {{- template "kyverno.annotations.merge" (list
    (toYaml .Values.customAnnotations)
    (toYaml .Values.cleanupController.service.annotations)
  ) -}}
{{- end -}}

{{- define "kyverno.cleanup-controller.serviceAccountAnnotations" -}}
  {{- template "kyverno.annotations.merge" (list
    (toYaml .Values.customAnnotations)
    (toYaml .Values.cleanupController.rbac.serviceAccount.annotations)
  ) -}}
{{- end -}}