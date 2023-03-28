{{/* vim: set filetype=mustache: */}}

{{- define "kyverno19.cleanup-controller.name" -}}
{{ template "kyverno19.name" . }}-cleanup-controller
{{- end -}}

{{- define "kyverno19.cleanup-controller.labels" -}}
app.kubernetes.io/part-of: {{ template "kyverno19.name" . }}
{{- with (include "kyverno19.helmLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "kyverno19.versionLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "kyverno19.cleanup-controller.matchLabels" .) }}
{{ . }}
{{- end }}
{{- end -}}

{{- define "kyverno19.cleanup-controller.matchLabels" -}}
app.kubernetes.io/component: cleanup-controller
app.kubernetes.io/name: {{ template "kyverno19.cleanup-controller.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "kyverno19.cleanup-controller.image" -}}
{{- if .image.registry -}}
  {{ .image.registry }}/{{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- else -}}
  {{ required "An image repository is required" .image.repository }}:{{ default .defaultTag .image.tag }}
{{- end -}}
{{- end -}}

{{- define "kyverno19.cleanup-controller.roleName" -}}
{{ .Release.Name }}:cleanup-controller
{{- end -}}

{{/* Create the name of the service account to use */}}
{{- define "kyverno19.cleanup-controller.serviceAccountName" -}}
{{- if .Values.kyverno.cleanupController.rbac.create -}}
    {{ default (include "kyverno19.cleanup-controller.name" .) .Values.kyverno.cleanupController.rbac.serviceAccount.name }}
{{- else -}}
    {{ required "A service account name is required when `rbac.create` is set to `false`" .Values.kyverno.cleanupController.rbac.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{- define "kyverno19.cleanup-controller.securityContext" -}}
{{- if semverCompare "<1.19" .Capabilities.KubeVersion.Version }}
{{ toYaml (omit .Values.kyverno.cleanupController.securityContext "seccompProfile") }}
{{- else }}
{{ toYaml .Values.kyverno.cleanupController.securityContext }}
{{- end }}
{{- end }}

{{/* Create the default PodDisruptionBudget to use */}}
{{- define "kyverno19.cleanup-controller.podDisruptionBudget.spec" -}}
{{- if and .Values.kyverno.cleanupController.podDisruptionBudget.minAvailable .Values.kyverno.cleanupController.podDisruptionBudget.maxUnavailable }}
{{- fail "Cannot set both .Values.kyverno.cleanupController.podDisruptionBudget.minAvailable and .Values.kyverno.cleanupController.podDisruptionBudget.maxUnavailable" -}}
{{- end }}
{{- if not .Values.kyverno.cleanupController.podDisruptionBudget.maxUnavailable }}
minAvailable: {{ default 1 .Values.kyverno.cleanupController.podDisruptionBudget.minAvailable }}
{{- end }}
{{- if .Values.kyverno.cleanupController.podDisruptionBudget.maxUnavailable }}
maxUnavailable: {{ .Values.kyverno.cleanupController.podDisruptionBudget.maxUnavailable }}
{{- end }}
{{- end }}

