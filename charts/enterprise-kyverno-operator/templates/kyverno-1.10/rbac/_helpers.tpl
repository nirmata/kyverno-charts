{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.rbac.labels.admin" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.rbac.matchLabels" .)
  "rbac.authorization.k8s.io/aggregate-to-admin: 'true'"
) -}}
{{- end -}}

{{- define "kyverno110.rbac.labels.view" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.common" .)
  (include "kyverno110.rbac.matchLabels" .)
  "rbac.authorization.k8s.io/aggregate-to-view: 'true'"
) -}}
{{- end -}}

{{- define "kyverno110.rbac.matchLabels" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.matchLabels.common" .)
  (include "kyverno110.labels.component" "rbac")
) -}}
{{- end -}}

{{- define "kyverno110.rbac.roleName" -}}
{{ .Release.Name }}:rbac
{{- end -}}
