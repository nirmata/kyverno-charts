{{/* vim: set filetype=mustache: */}}

{{- define "kyverno110.labels.merge" -}}
{{- $labels := dict -}}
{{- range . -}}
  {{- $labels = merge $labels (fromYaml .) -}}
{{- end -}}
{{- with $labels -}}
  {{- toYaml $labels -}}
{{- end -}}
{{- end -}}

{{- define "kyverno110.labels.helm" -}}
helm.sh/chart: {{ template "kyverno110.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "kyverno110.labels.version" -}}
app.kubernetes.io/version: {{ template "kyverno110.chartVersion" . }}
{{- end -}}

{{- define "kyverno110.labels.common" -}}
{{- template "kyverno110.labels.merge" (list
  (include "kyverno110.labels.helm" .)
  (include "kyverno110.labels.version" .)
  (toYaml .Values.kyverno.kyverno.customLabels)
) -}}
{{- end -}}

{{- define "kyverno110.matchLabels.common" -}}
app.kubernetes.io/part-of: {{ template "kyverno110.fullname" . }}
app.kubernetes.io/instance: {{ template "kyverno110.name" . }}
{{- end -}}

{{- define "kyverno110.labels.component" -}}
app.kubernetes.io/component: {{ . }}
{{- end -}}

{{- define "kyverno110.labels.name" -}}
app.kubernetes.io/name: {{ . }}
{{- end -}}
