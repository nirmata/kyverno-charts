{{/* vim: set filetype=mustache: */}}

{{- define "kyverno.pdb.apiVersion" -}}
  {{- .Values.apiVersionOverride.podDisruptionBudget -}}
{{- end -}}

{{- define "kyverno.pdb.spec" -}}
{{- if and .minAvailable .maxUnavailable -}}
  {{- fail "Cannot set both .minAvailable and .maxUnavailable" -}}
{{- end -}}
{{- if not .maxUnavailable }}
minAvailable: {{ default 1 .minAvailable }}
{{- end }}
{{- if .maxUnavailable }}
maxUnavailable: {{ .maxUnavailable }}
{{- end }}
{{- end -}}