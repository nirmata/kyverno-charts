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
      securityContext: NULLOBJ
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
        imageTag: "v0.1.2"
        productName: ""
{{- end -}}

{{- define "enterprise-kyverno.combinedKyveroHelm" }}

{{- if .Values.kyverno.helm }}
{{- (merge .Values.kyverno.helm (include "enterprise-kyverno.kyveroDefaultHelm" . | fromYaml).content) | toYaml -}}
{{- else -}}
{{- (include "enterprise-kyverno.kyveroDefaultHelm" . | fromYaml).content | toYaml -}}
{{- end}}
{{- end -}}
