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

      {{- if eq .Values.kyverno.enablePolicyExceptions true }}
      features:
        policyExceptions: 
          enabled: true
          namespace: {{ include "kyverno.namespace" . }}
      {{- end }}

      {{- if .Values.kyverno.helm }}
      {{- toYaml .Values.kyverno.helm | nindent 6 }}
      {{- end}}
      admissionController:
        container:
          image:
            tag: {{ .Values.kyverno.image.tag }}
        initContainer:
          image:
            tag: {{ .Values.kyverno.image.tag }}
        imagePullSecrets:
        - name: image-pull-secret
      backgroundController:
        image:
          tag: {{ .Values.kyverno.image.tag }}
        imagePullSecrets:
        - name: image-pull-secret
      cleanupController:
        image:
          tag: {{ .Values.kyverno.image.tag }}
        imagePullSecrets:
        - name: image-pull-secret
      reportsController:
        image:
          tag: {{ .Values.kyverno.image.tag }}
        imagePullSecrets:
        - name: image-pull-secret
      clusterAdmissionReports:
        imagePullSecrets:
        - name: image-pull-secret
      cleanupJobs:
        admissionReports:
          imagePullSecrets:
          - name: image-pull-secret
          image:
            registry: {{.Values.kyverno.cleanupJobsRegistry}}
        clusterAdmissionReports:
          imagePullSecrets:
          - name: image-pull-secret
          image:
            registry: {{.Values.kyverno.cleanupJobsRegistry}}
      {{- if .Values.image.pullSecrets.create }}
      imagePullSecrets:
        image-pull-secret:
          registry: {{.Values.image.pullSecrets.registry}}
          username: {{.Values.image.pullSecrets.username}}
          password: {{.Values.image.pullSecrets.password}}
      {{- end}}
      licenseManager:
        imageRepository: {{ .Values.kyverno.image.repository }}/nirmata/kyverno-license-manager
        imageTag: "v0.1.3"
        productName: ""
{{- end -}}

{{- define "enterprise-kyverno.combinedKyveroHelm" }}

{{- if .Values.kyverno.helm }}
{{- (merge .Values.kyverno.helm (include "enterprise-kyverno.kyveroDefaultHelm" . | fromYaml).content) | toYaml -}}
{{- else -}}
{{- (include "enterprise-kyverno.kyveroDefaultHelm" . | fromYaml).content | toYaml -}}
{{- end}}
{{- end -}}
