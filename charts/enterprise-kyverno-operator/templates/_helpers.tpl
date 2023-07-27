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
{{- $excludedNamespaces := .Values.kyverno.excludedNamespacesForWebhook }}
{{- if eq 0 (len .Values.kyverno.excludedNamespacesForWebhook) }}
    {{- $defaultNamespaces := list "kube-system" "nirmata" "nirmata-system" -}}
    {{- $excludedNamespaces = concat $defaultNamespaces .Values.kyverno.excludedNamespacesForWebhook -}}
{{- end -}}
{{ toJson $excludedNamespaces }}
{{- end }}

{{- define "enterprise-kyverno.kyveroDefaultHelm" -}}
content:
      config:
        webhooks:
        #Exclude namespaces
        - namespaceSelector:
            matchExpressions:
            - key: kubernetes.io/metadata.name
              operator: NotIn
              values:
              {{- $excludedNamespaces := include "kyverno.excludedNamespaces" . | fromJsonArray }}
              {{- range $excludedNamespaces}}
              - {{.}}
              {{- end }}
        {{- if eq .Values.cloudPlatform "aks" }}
        webhookAnnotations:
            'admissions.enforcer/disabled': 'true'
        {{- end}}
        
      {{- if eq .Values.cloudPlatform "openshift" }}
      securityContext: null
      {{- end}}


      {{- if eq .Values.cloudPlatform "eks" }}
      hostNetwork: true
      {{- end }}

      cleanupController:
        image:
          repository: {{ trimSuffix "kyverno" .Values.kyverno.image.repository  }}cleanup-controller
          tag: {{ .Values.kyverno.image.tag }}
          pullSecrets:
          - name: image-pull-secret
      image:
        pullSecrets:
        {{- if (contains "v1.9" .Values.kyverno.image.tag) }}
        - name: image-pull-secret
        {{- else if (contains "v1.8" .Values.kyverno.image.tag)}}
          name: image-pull-secret
        {{- end }}
      initImage:
        repository: {{ trimSuffix "kyverno" .Values.kyverno.image.repository  }}kyvernopre
        tag: {{ .Values.kyverno.image.tag }}
      {{- if .Values.image.pullSecrets.create }}
      imagePullSecrets:
        image-pull-secret:
          registry: {{.Values.image.pullSecrets.registry}}
          username: {{.Values.image.pullSecrets.username}}
          password: {{.Values.image.pullSecrets.password}}
      {{- end}}
      {{- if and (eq .Values.kyverno.enablePolicyExceptions true) (contains "v1.9" .Values.kyverno.image.tag) }}
      extraArgs:
      - --enablePolicyException=true
      - --loggingFormat=text
      - --exceptionNamespace={{ include "kyverno.namespace" . }}
      {{- end }}
      rbac:
        serviceAccount:
          name: kyverno
      licenseManager:
        imageRepository: {{ trimSuffix "kyverno" .Values.kyverno.image.repository  }}kyverno-license-manager
        imageTag: "v0.1.1"
        productName: ""
{{- end -}}

{{- define "enterprise-kyverno.combinedKyveroHelm" }}

{{- if .Values.kyverno.helm }}
{{- (merge .Values.kyverno.helm (include "enterprise-kyverno.kyveroDefaultHelm" . | fromYaml).content) | toYaml -}}
{{- else -}}
{{- (include "enterprise-kyverno.kyveroDefaultHelm" . | fromYaml).content | toYaml -}}
{{- end}}
{{- end -}}