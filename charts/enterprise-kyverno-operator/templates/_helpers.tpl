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
{{- if or (contains $name .Release.Name) (contains .Release.Name $name) }}
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

{{/* Get the namespace name. */}}
{{- define "kyverno-aws-adapter.namespace" -}}
{{- if .Values.awsAdapter.namespace -}}
    {{- .Values.awsAdapter.namespace -}}
{{- else -}}
    {{- "kyverno-aws-adapter" -}}
{{- end -}}
{{- end -}}

{{/* Get the namespace name. */}}
{{- define "image-scan-adapter.namespace" -}}
{{- if .Values.imageScanAdapter.namespace -}}
    {{- .Values.imageScanAdapter.namespace -}}
{{- else -}}
    {{- "image-scan-adapter" -}}
{{- end -}}
{{- end -}}

{{/* Get the namespace name. */}}
{{- define "kube-bench.namespace" -}}
{{- if .Values.cisAdapter.namespace -}}
    {{- .Values.cisAdapter.namespace -}}
{{- else -}}
    {{- "cis-adapter" -}}
{{- end -}}
{{- end -}}

{{/*
Create secret to access container registry
*/}}
{{- define "imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.image.pullSecrets.registry (printf "%s:%s" .Values.image.pullSecrets.username .Values.image.pullSecrets.password | b64enc) | b64enc }}
{{- end }}

{{- define "enterprise-kyverno.managecerts" -}}
{{- if eq .Values.certManager "operator" -}}
    {{- true -}}
{{- else -}}
    {{- false -}}
{{- end -}}
{{- end -}}

{{- define "enterprise-kyverno.kyvernoReplicas" -}}
{{- if eq .Values.profile "dev" -}}
    {{- default 1 .Values.kyverno.replicaCount -}}
{{- else if eq .Values.profile "prod" -}}
    {{- default 3 .Values.kyverno.replicaCount -}}
{{- else -}}
    {{- default 1 .Values.kyverno.replicaCount -}}
{{- end -}}
{{- end -}}

{{- define "enterprise-kyverno.preventPolicyTamper" -}}
{{- $polTamperStr := lower (toString .Values.preventPolicyTamper) }}

{{- if eq $polTamperStr "false" }}
    {{- false }}
{{- else if eq $polTamperStr "true"}}
    {{- true }}
{{- else }}
    {{- if eq .Values.profile "dev" -}}
        {{- false }}
    {{- else if eq .Values.profile "prod" -}}
        {{- true }}
    {{- else -}}
        {{- true }}
    {{- end -}}
{{- end}}

{{- end -}}

{{- define "enterprise-kyverno.enabledPolicysets" -}}
{{- if eq .Values.profile "dev" -}}
    {{- default ("pod-security-baseline") (join "," .Values.policies.policySets) -}}
{{- else if eq .Values.profile "prod" -}}
    {{- default ("pod-security-restricted,pod-security-baseline,rbac-best-practices") (join "," .Values.policies.policySets) -}}
{{- else -}}
    {{- default ("pod-security-restricted,pod-security-baseline") (join "," .Values.policies.policySets) -}}
{{- end -}}
{{- end -}}

{{- define "enterprise-kyverno.policysetsStr" -}}
{{- range (include "enterprise-kyverno.enabledPolicysets" . | split ",") }}{{(print . " ") }} {{- end }}
{{- end -}}

{{- define "kyverno.excludedNamespaces" -}}
{{- $defaultNamespaces := list "kube-system" "nirmata" "nirmata-system" -}}
{{- $excludedNamespaces := .Values.kyverno.excludedNamespacesForWebhook }}
{{- if .Values.kyverno.excludedNamespacesOverride }}
    {{- $excludedNamespaces = .Values.kyverno.excludedNamespacesForWebhook -}}
{{- else -}}
    {{- $excludedNamespaces = concat $defaultNamespaces .Values.kyverno.excludedNamespacesForWebhook -}}
{{- end -}}
{{ toJson $excludedNamespaces }}
{{- end }}
