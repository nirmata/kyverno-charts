{{- define "controller.imagePullSecret" }}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .imageRegistry (printf "%s:%s" .registryUserName .registryPassword | b64enc) | b64enc }}
{{- end }}

{{- define "controller.metricsEndpointDomain" }}
{{- $url := .Values.nirmataURL | default "wss://nirmata.io/tunnels" }}
{{- $withoutProtocol := $url | trimPrefix "wss://" | trimPrefix "ws://" | trimPrefix "https://" | trimPrefix "http://" }}
{{- $domain := $withoutProtocol | splitList "/" | first }}
{{- $domain }}
{{- end }}
{{/*
Proxy environment variables. Each variable is rendered only when its value is set,
so setting just proxy.httpsProxy is enough to route the wss/https traffic through the proxy.
*/}}
{{- define "controller.proxyEnv" }}
{{- with .Values.proxy.httpProxy }}
- name: HTTP_PROXY
  value: {{ . | quote }}
{{- end }}
{{- with .Values.proxy.httpsProxy }}
- name: HTTPS_PROXY
  value: {{ . | quote }}
{{- end }}
{{- with .Values.proxy.noProxy }}
- name: NO_PROXY
  value: {{ . | quote }}
{{- end }}
{{- end }}
