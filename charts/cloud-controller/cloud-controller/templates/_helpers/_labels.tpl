{{/* vim: set filetype=mustache: */}}

{{- define "cloud-control.labels.merge" -}}
{{- $labels := dict -}}
{{- range . -}}
  {{- $labels = merge $labels (fromYaml .) -}}
{{- end -}}
{{- with $labels -}}
  {{- toYaml $labels -}}
{{- end -}}
{{- end -}}

{{- define "cloud-control.labels.helm" -}}
helm.sh/chart: {{ template "cloud-control.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end -}}

{{- define "cloud-control.labels.version" -}}
app.kubernetes.io/version: {{ template "cloud-control.chartVersion" . }}
{{- end -}}

{{- define "cloud-control.labels.common" -}}
{{- template "cloud-control.labels.merge" (list
  (include "cloud-control.labels.helm" .)
  (include "cloud-control.labels.version" .)
) -}}
{{- end -}}

{{- define "cloud-control.matchLabels.common" -}}
app.kubernetes.io/part-of: {{ template "cloud-control.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end -}}

{{- define "cloud-control.labels.component" -}}
app.kubernetes.io/component: {{ . }}
{{- end -}}

{{- define "cloud-control.labels.name" -}}
app.kubernetes.io/name: {{ . }}
{{- end -}}