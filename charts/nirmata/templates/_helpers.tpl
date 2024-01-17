{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.chartVersion" -}}
{{- if .Values.templating.enabled -}}
  {{- required "templating.version is required when templating.enabled is true" .Values.templating.version | replace "+" "_" -}}
{{- else -}}
  {{- .Chart.Version | replace "+" "_" -}}
{{- end -}}
{{- end -}}

{{- define "kyverno.features.flags" -}}
{{- $flags := list -}}
{{- with .admissionReports -}}
  {{- $flags = append $flags (print "--admissionReports=" .enabled) -}}
{{- end -}}
{{- with .aggregateReports -}}
  {{- $flags = append $flags (print "--aggregateReports=" .enabled) -}}
{{- end -}}
{{- with .policyReports -}}
  {{- $flags = append $flags (print "--policyReports=" .enabled) -}}
{{- end -}}
{{- with .validatingAdmissionPolicyReports -}}
  {{- $flags = append $flags (print "--validatingAdmissionPolicyReports=" .enabled) -}}
{{- end -}}
{{- with .autoUpdateWebhooks -}}
  {{- $flags = append $flags (print "--autoUpdateWebhooks=" .enabled) -}}
{{- end -}}
{{- with .disableAutoWebhookGeneration -}}
  {{- $flags = append $flags (print "--disableAutoWebhookGeneration=" .enabled) -}}
{{- end -}}
{{- with .backgroundScan -}}
  {{- $flags = append $flags (print "--backgroundScan=" .enabled) -}}
  {{- $flags = append $flags (print "--backgroundScanWorkers=" .backgroundScanWorkers) -}}
  {{- $flags = append $flags (print "--backgroundScanInterval=" .backgroundScanInterval) -}}
  {{- $flags = append $flags (print "--skipResourceFilters=" .skipResourceFilters) -}}
{{- end -}}
{{- with .configMapCaching -}}
  {{- $flags = append $flags (print "--enableConfigMapCaching=" .enabled) -}}
{{- end -}}
{{- with .deferredLoading -}}
  {{- $flags = append $flags (print "--enableDeferredLoading=" .enabled) -}}
{{- end -}}

{{/* CRD labels */}}
{{- define "kyverno.crdLabels" -}}
app.kubernetes.io/component: kyverno
{{- with (include "kyverno.helmLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "kyverno.matchLabels" .) }}
{{ . }}
{{- end }}
app.kubernetes.io/part-of: {{ template "kyverno.name" . }}
{{- with (include "kyverno.versionLabels" .) }}
{{ . }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kyverno.labels" -}}
app.kubernetes.io/component: kyverno
{{- with (include "kyverno.helmLabels" .) }}
{{ . }}
{{- end }}
{{- with (include "kyverno.matchLabels" .) }}
{{ . }}
{{- end }}
app.kubernetes.io/part-of: {{ template "kyverno.name" . }}
{{- with (include "kyverno.versionLabels" .) }}
{{ . }}
{{- end }}
{{- if .Values.customLabels }}
{{ toYaml .Values.customLabels }}
{{- end }}
{{- end -}}

{{/* Helm required labels */}}
{{- define "kyverno.test-labels" -}}
{{- with (include "kyverno.helmLabels" .) }}
{{ . }}
{{- end }}
app: kyverno
app.kubernetes.io/component: kyverno
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/name: {{ template "kyverno.name" . }}-test
app.kubernetes.io/part-of: {{ template "kyverno.name" . }}
app.kubernetes.io/version: "{{ .Chart.Version | replace "+" "_" }}"
{{- end -}}

{{/* matchLabels */}}
{{- define "kyverno.matchLabels" -}}
{{- if .Values.templating.enabled -}}
  {{- required "templating.version is required when templating.enabled is true" .Values.templating.version | replace "+" "_" -}}
{{- else -}}
  {{- .Chart.Version | replace "+" "_" -}}
{{- end -}}
{{- end -}}