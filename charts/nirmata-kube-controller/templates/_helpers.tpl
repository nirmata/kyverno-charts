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
{{/*
controller.otelExternalLabels renders the `external_labels` block of the otel-agent
prometheusremotewrite exporter (text, no leading/trailing newline), or nothing.

Why: after first registration the controller patches
`exporters.prometheusremotewrite.external_labels.{clusterId,tenantId}` into the live
`otel-agent-config` ConfigMap, and reads clusterId back from it on startup (a missing
clusterId triggers re-registration). Because the ConfigMap is Helm-managed, a plain
`helm upgrade` would re-render it without those labels and wipe the cluster identity.

Resolution order:
  1. LIVE ConfigMap (via `lookup`): if the existing `otel-agent-config` already holds a
     complete identity (clusterId AND tenantId, both non-empty strings) it is preserved
     verbatim. It always wins, so a stale pinned value can never overwrite an identity the
     controller freshly registered (e.g. after re-onboarding the cluster).
  2. Values fallback: `cluster.id` + `cluster.tenantId`, used only when the live ConfigMap
     has no complete identity: a fresh install, or a renderer with no cluster access
     (`helm template`, Argo CD), where `lookup` always returns nothing.
  3. Otherwise nothing is rendered and the controller registers itself and writes both IDs.

`cluster.id` and `cluster.tenantId` must be set together: the render fails whenever exactly
one of them is set, regardless of live state.

The live config.yaml is walked level by level, guarding each level with `kindIs "map"`
(sprig `dig` would panic on a non-map intermediate such as `exporters: null`), and live IDs
that are not strings (null, numbers, maps) are treated as absent.

The block is emitted ONLY when both IDs are known. With just one of them the controller
would skip registration (clusterId present) while the otel-agent `wait-for-tenantid`
initContainer waits forever for tenantId; emitting nothing instead lets the controller
re-register and write both.
*/}}
{{- define "controller.otelExternalLabels" -}}
{{- $cluster := .Values.cluster | default dict -}}
{{- if or (and $cluster.id (not $cluster.tenantId)) (and $cluster.tenantId (not $cluster.id)) -}}
  {{- fail "cluster.id and cluster.tenantId must be set together (or both left empty)" -}}
{{- end -}}
{{- $id := "" -}}
{{- $tenantId := "" -}}
{{- /* 1. Identity already present in the live ConfigMap wins. */ -}}
{{- $existing := lookup "v1" "ConfigMap" .Values.namespace "otel-agent-config" | default dict -}}
{{- $cfg := fromYaml (dig "data" "config.yaml" "" $existing) | default dict -}}
{{- $exporters := get $cfg "exporters" -}}
{{- if kindIs "map" $exporters -}}
  {{- $prw := get $exporters "prometheusremotewrite" -}}
  {{- if kindIs "map" $prw -}}
    {{- $labels := get $prw "external_labels" -}}
    {{- if kindIs "map" $labels -}}
      {{- $liveId := get $labels "clusterId" -}}
      {{- $liveTenantId := get $labels "tenantId" -}}
      {{- if and (kindIs "string" $liveId) (kindIs "string" $liveTenantId) $liveId $liveTenantId -}}
        {{- $id = $liveId -}}
        {{- $tenantId = $liveTenantId -}}
      {{- end -}}
    {{- end -}}
  {{- end -}}
{{- end -}}
{{- /* 2. Fall back to the values (validated above to be both set or both empty). */ -}}
{{- if and (not $id) $cluster.id $cluster.tenantId -}}
  {{- $id = toString $cluster.id -}}
  {{- $tenantId = toString $cluster.tenantId -}}
{{- end -}}
{{- if and $id $tenantId -}}
external_labels:
  clusterId: {{ $id | quote }}
  tenantId: {{ $tenantId | quote }}
{{- end -}}
{{- end }}
