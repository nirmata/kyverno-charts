{{/*
Expand the name of the chart.
*/}}
{{- define "enterprise-kyverno.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "enterprise-kyverno.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "enterprise-kyverno.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "enterprise-kyverno.labels" -}}
helm.sh/chart: {{ include "enterprise-kyverno.chart" . }}
{{ include "enterprise-kyverno.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "enterprise-kyverno.selectorLabels" -}}
app.kubernetes.io/name: {{ include "enterprise-kyverno.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
control-plane: {{ include "enterprise-kyverno.name" . }}-controller-manager
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "enterprise-kyverno.rbac.serviceAccountName" -}}
{{- if .Values.rbac.serviceAccount.create }}
{{- default (include "enterprise-kyverno.fullname" .) .Values.rbac.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.rbac.serviceAccount.name }}
{{- end }}
{{- end }}

{{- define "enterprise-kyverno.namespace" -}}
{{- if .Values.namespace -}}
    {{- .Values.namespace -}}
{{- else -}}
    {{- .Release.Namespace -}}
{{- end -}}
{{- end -}}

{{/* Get the namespace name. */}}
{{- define "kyverno.namespace" -}}
{{- if .Values.kyverno.namespace -}}
    {{- .Values.kyverno.namespace -}}
{{- else -}}
    {{- "kyverno" -}}
{{- end -}}
{{- end -}}

{{/*
Create secret to access container registry
*/}}
{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.pullSecrets.registry (printf "%s:%s" .Values.image.pullSecrets.username .Values.image.pullSecrets.password | b64enc) | b64enc }}
{{- end }}

{{- define "enterprise-kyverno.policysets" -}}
{{- if .Values.policies.policySets }}
{{- range .Values.policies.policySets }}{{(print .name " ") }} {{- end }}
{{- else -}}
{{- "" -}}
{{- end -}}
{{- end -}}
