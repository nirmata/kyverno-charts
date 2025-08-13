{{- define "controller.imagePullSecret" }}
{{- printf "{\"auths\":{\"%s\":{\"auth\":\"%s\"}}}" .imageRegistry (printf "%s:%s" .registryUserName .registryPassword | b64enc) | b64enc }}
{{- end }}

{{- define "controller.metricsEndpointDomain" }}
{{- $url := .Values.nirmataURL | default "wss://nirmata.io/tunnels" }}
{{- $withoutProtocol := $url | trimPrefix "wss://" | trimPrefix "ws://" | trimPrefix "https://" | trimPrefix "http://" }}
{{- $domain := $withoutProtocol | splitList "/" | first }}
{{- $domain }}
{{- end }}