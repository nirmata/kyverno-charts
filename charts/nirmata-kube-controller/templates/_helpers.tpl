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

{{/*
controller.policyExceptionKinds: the single source of truth for every PolicyException kind the
controller needs RBAC for and/or watches. nirmata-kube-controller.yaml renders it, via
`include "controller.policyExceptionKinds" . | fromYamlArray`, into FOUR places, so they can no
longer drift apart:

  1. nirmata:readonly                           get/list/watch      (always rendered)
  2. nirmata:policy-exceptions                  create/update/patch/delete (policyExceptions feature)
  3. nirmata:kyverno-cleanup-policy-exceptions  get/list/watch/delete      (policyExceptions feature
                                                and kyvernoCleanup.policyExceptionRbac.enabled)
  4. WatchedResources in nirmata-kube-controller-config (one `policyexceptions.<version>.<group>`
     line per entry of `watchVersions`)

This is a template and NOT a values.yaml key on purpose: `helm upgrade --reuse-values` keeps the
values of the previous release and a brand new values key would arrive empty, silently dropping
the RBAC rules and watch entries rendered from it.

Output: a YAML list; each item has
  group:         the API group of the PolicyException CRD. Gets RBAC rules in roles 1-3.
  watchVersions: the served versions NCH ingests events for, as `<version>` strings. Each one
                 becomes a `policyexceptions.<version>.<group>` WatchedResources line. It MUST only
                 contain versions the CRD serves (a watch on an unserved version fails). Use `[]`
                 to grant RBAC without watching.

Kinds (served versions taken from the Kyverno CRDs shipped by enterprise-kyverno 1.14 - 1.19):

  | group               | served versions                      | watched here  |
  |---------------------|--------------------------------------|---------------|
  | kyverno.io          | v2 (storage), v2beta1                | v2beta1, v2   |
  | policies.kyverno.io | v1alpha1 (1.14+), v1beta1 (1.16+),   | none          |
  |                     | v1 (1.17+)                           |               |

  kyverno.io v2alpha1 is NOT served by any Kyverno release, so it must never be watched.

policies.kyverno.io (the CEL based PolicyException) gets RBAC but is deliberately NOT watched:
NCH ingests exception events by kind only (K8sChangeEventsHandler -> PolicyExceptionUtils
.createFromJson) and cannot parse CEL exceptions, so streaming them would only produce events it
cannot handle. Set `watchVersions` for it here once NCH can ingest them.

To add a kind: append an item here. The chart's own readonly, write and cleanup roles and watch
list pick it up with no further template change, but three other places do NOT and must be updated
in the same change:

  - the chart test fixtures: `wantExceptionKinds` (and `unwatchedExceptionGroups` if the group must
    not be watched) in test/chart/exceptions_test.go, and the hard-coded group list in
    assertCleanupRole in test/chart/cleanup_rbac_test.go. `make test-chart` fails until they match.
  - the hand-kept java-cluster copies: K8sClientUtils.generateKubeControllerConfig (service-cluster),
    K8sUtils.generateKubeControllerConfig (lib-provider-k8s-cluster) and
    service-cluster/.../controller/policyexception-role.yaml, plus java-cluster's
    KubeControllerExceptionCoverageTest (its pinned EXCEPTION_GROUPS mirror of this list) and the
    exact-match role constants in K8sClientUtilsTests. java-cluster cannot render this chart and
    nothing compares the two, so a change here alone fails no java-cluster test.
  - the kinds table above and the README section "Helm chart: policy exception RBAC and watch
    list".

Note: `policyexceptions/status` is granted on every group (read and write roles); granting a
subresource that a given CRD does not define is harmless in RBAC.
*/}}
{{- define "controller.policyExceptionKinds" -}}
- group: kyverno.io
  watchVersions: [v2beta1, v2]
- group: policies.kyverno.io
  watchVersions: []
{{- end -}}
