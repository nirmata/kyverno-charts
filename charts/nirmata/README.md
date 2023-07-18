# kyverno

Kubernetes Native Policy Management

![Version: 3.0.2](https://img.shields.io/badge/Version-3.0.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v1.10.1-n4k.nirmata.1](https://img.shields.io/badge/AppVersion-v1.10.1--n4k.nirmata.1-informational?style=flat-square)

## About

[Kyverno](https://kyverno.io) is a Kubernetes Native Policy Management engine.

It allows you to:
- Manage policies as Kubernetes resources (no new language required.)
- Validate, mutate, and generate resource configurations.
- Select resources based on labels and wildcards.
- View policy enforcement as events.
- Scan existing resources for violations.

This chart bootstraps a Kyverno deployment on a [Kubernetes](http://kubernetes.io) cluster using the [Helm](https://helm.sh) package manager.

Access the complete user documentation and guides at: https://kyverno.io.

## (Recommended) Manage Kyverno through new Enterprise Kyverno Operator
Install the Enterprise Kyverno Operator following instructions [here](https://github.com/nirmata/kyverno-charts/blob/main/charts/enterprise-kyverno-operator/README.md). The operator will manage Kyverno lifecycle.

## Direct installation through the Enterprise Kyverno Helm Chart
We recommend managing Kyverno lifecycle through the Enterprise Kyverno Operator mentioned above. This section is for users managing Kyverno directly through its Helm Chart.

**IMPORTANT IMPORTANT IMPORTANT IMPORTANT**

This chart changed significantly between `v1` and `v3` (corresponding to upstream kyverno chart versions v2 and v3). If you are upgrading from `v1`, please read `Migrating from v1 to v3` section.

**Add the Kyverno Helm repository:**

```console
helm repo add nirmata https://nirmata.github.io/kyverno-charts/
helm repo update nirmata
```

**Note:** If you have open source Kyverno installed, please follow the instructions below to upgrade to the Nirmata Enterprise Subscription.

**Create a namespace:**

**Note:** You can skip this step if you have already created the kyverno namespace.

You can install Kyverno in any namespace. The examples use `kyverno` as the namespace.

```console
kubectl create namespace kyverno
```

**(Optional)** If a custom CA is used, create a configmap corresponding to the same with key custom-ca.pem. E.g.
kubectl -n kyverno create configmap <e.g. ca-store-cm> --from-file=custom-ca.pem=<cert file e.g. some-cert.pem>

**Install the Kyverno chart:**

```console
helm install kyverno --namespace kyverno --create-namespace nirmata/kyverno --set licenseManager.licenseKey=<license key>[,licenseManager.apiKey=<api key>]
```

**(Optional)** Other parameters corresponding to custom CA or HTTP proxies, NO_PROXY should be provided to the above command as needed. E.g.
```console
--set customCAConfigMap=<e.g. ca-store-cm> --set systemCertPath=<e.g. /etc/ssl/certs> --set "extraEnvVars[0].name=HTTP_PROXY" --set "extraEnvVars[0].value=<e.g. http://test.com:8080>" ...
```

The command deploys Kyverno on the Kubernetes cluster with default configuration. The [installation](https://kyverno.io/docs/installation/) guide lists the parameters that can be configured during installation.

The Kyverno ClusterRole/ClusterRoleBinding that manages webhook configurations must have the suffix `:webhook`. Ex., `*:webhook` or `kyverno:webhook`.
Other ClusterRole/ClusterRoleBinding names are configurable.

## Installing the YAML

If you do not want to use "helm install" to install the chart, you can generate the YAML from the helm chart and install it directly.
Add the Kyverno Helm repository as described above. Then create the namespace for kyverno. Once the namespace is created, generate the kyverno YAML file using the helm template command

```console
helm template kyverno --namespace=kyverno nirmata/kyverno --create-namespace --set licenseManager.licenseKey=<license key>[,licenseManager.apiKey=<api key>] > kyverno.yaml

kubectl create -f kyverno.yaml
```

**Notes on using ArgoCD:**

When deploying this chart with ArgoCD you will need to enable `Replace` in the `syncOptions`, and you probably want to ignore diff in aggregated cluster roles.

You can do so by following instructions in these pages of ArgoCD documentation:
- [Enable Replace in the syncOptions](https://argo-cd.readthedocs.io/en/stable/user-guide/sync-options/#replace-resource-instead-of-applying-changes)
- [Ignore diff in aggregated cluster roles](https://argo-cd.readthedocs.io/en/stable/user-guide/diffing/#ignoring-rbac-changes-made-by-aggregateroles)

ArgoCD uses helm only for templating but applies the results with `kubectl`.

Unfortunately `kubectl` adds metadata that will cross the limit allowed by Kubernetes. Using `Replace` overcomes this limitation.

Another option is to use server side apply, this will be supported in ArgoCD v2.5.

Finally, we introduced new CRDs in 1.8 to manage resource-level reports. Those reports are associated with parent resources using an `ownerReference` object.

As a consequence, ArgoCD will show those reports in the UI, but as they are managed dynamically by Kyverno it can pollute your dashboard.

You can tell ArgoCD to ignore reports globally by adding them under the `resource.exclusions` stanza in the ArgoCD ConfigMap.

```yaml
    resource.exclusions: |
      - apiGroups:
          - kyverno.io
        kinds:
          - AdmissionReport
          - BackgroundScanReport
          - ClusterAdmissionReport
          - ClusterBackgroundScanReport
        clusters:
          - '*'
```

Below is an example of ArgoCD Application manifest that should work with this chart.

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: kyverno
  namespace: argocd
spec:
  destination:
    namespace: kyverno
    server: https://kubernetes.default.svc
  project: default
  source:
    chart: kyverno
    repoURL: https://kyverno.github.io/kyverno
    targetRevision: 2.6.0
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
      - Replace=true
```

## Migrating from v2 to v3

In `v3` chart values changed significantly, please read the instructions below to migrate your values:

- `config.metricsConfig` is now `metricsConfig`
- `resourceFiltersExcludeNamespaces` has been replaced with `config.resourceFiltersExcludeNamespaces`
- `excludeKyvernoNamespace` has been replaced with `config.excludeKyvernoNamespace`
- `config.existingConfig` has been replaced with `config.create` and `config.name` to __support bring your own config__
- `config.existingMetricsConfig` has been replaced with `metricsConfig.create` and `metricsConfig.name` to __support bring your own config__
- `namespace` has been renamed `namespaceOverride`
- `installCRDs` has been replaced with `crds.install`
- `testImage` has been replaced with `test.image`
- `testResources` has been replaced with `test.resources`
- `testSecurityContext` has been replaced with `test.securityContext`
- `replicaCount` has been replaced with `admissionController.replicas`
- `updateStrategy` has been replaced with `admissionController.updateStrategy`
- `priorityClassName` has been replaced with `admissionController.priorityClassName`
- `hostNetwork` has been replaced with `admissionController.hostNetwork`
- `dnsPolicy` has been replaced with `admissionController.dnsPolicy`
- `nodeSelector` has been replaced with `admissionController.nodeSelector`
- `tolerations` has been replaced with `admissionController.tolerations`
- `topologySpreadConstraints` has been replaced with `admissionController.topologySpreadConstraints`
- `podDisruptionBudget` has been replaced with `admissionController.podDisruptionBudget`
- `antiAffinity` has been replaced with `admissionController.antiAffinity`
- `antiAffinity.enable` has been replaced with `admissionController.antiAffinity.enabled`
- `podAntiAffinity` has been replaced with `admissionController.podAntiAffinity`
- `podAffinity` has been replaced with `admissionController.podAffinity`
- `nodeAffinity` has been replaced with `admissionController.nodeAffinity`
- `startupProbe` has been replaced with `admissionController.startupProbe`
- `livenessProbe` has been replaced with `admissionController.livenessProbe`
- `readinessProbe` has been replaced with `admissionController.readinessProbe`
- `createSelfSignedCert` has been replaced with `admissionController.createSelfSignedCert`
- `serviceMonitor` has been replaced with `admissionController.serviceMonitor`
- `podSecurityContext` has been replaced with `admissionController.podSecurityContext`
- `tufRootMountPath` has been replaced with `admissionController.tufRootMountPath`
- `sigstoreVolume` has been replaced with `admissionController.sigstoreVolume`
- `initImage` has been replaced with `admissionController.initContainer.image`
- `initResources` has been replaced with `admissionController.initContainer.resources`
- `image` has been replaced with `admissionController.container.image`
- `image.pullSecrets` has been replaced with `admissionController.imagePullSecrets`
- `resources` has been replaced with `admissionController.container.resources`
- `service` has been replaced with `admissionController.service`
- `metricsService` has been replaced with `admissionController.metricsService`
- `initContainer.extraArgs` has been replaced with `admissionController.initContainer.extraArgs`
- `envVarsInit` has been replaced with `admissionController.initContainer.extraEnvVars`
- `envVars` has been replaced with `admissionController.container.extraEnvVars`
- `extraArgs` has been replaced with `admissionController.container.extraArgs`
- `extraInitContainers` has been replaced with `admissionController.extraInitContainers`
- `extraContainers` has been replaced with `admissionController.extraContainers`
- `podLabels` has been replaced with `admissionController.podLabels`
- `podAnnotations` has been replaced with `admissionController.podAnnotations`
- `securityContext` has been replaced with `admissionController.container.securityContext` and `admissionController.initContainer.securityContext`
- `rbac` has been replaced with `admissionController.rbac`
- `generatecontrollerExtraResources` has been replaced with `admissionController.rbac.clusterRole.extraResources`
- `networkPolicy` has been replaced with `admissionController.networkPolicy`
- all `extraArgs` now use objects instead of arrays
- logging, tracing and metering are now configured using `*Controller.logging`, `*Controller.tracing` and `*Controller.metering`

- Labels and selectors have been reworked and due to immutability, upgrading from `v2` to `v3` is going to be rejected. The easiest solution is to uninstall `v2` and reinstall `v3` once values have been adapted to the changes described above.

- Image tags are now validated and must be strings, if you use image tags in the `1.35` form please add quotes around the tag value.

- Image references are now using the `registry` setting, if you override the registry or repository fields please use `registry` (`--set image.registry=ghcr.io --set image.repository=nirmata/kyverno` instead of `--set image.repository=ghcr.io/nirmata/kyverno`).

- Admission controller `Deployment` name changed from `kyverno` to `kyverno-admission-controller`.
- `config.excludeUsername` was renamed to `config.excludeUsernames`
- `config.excludeGroupRole` was renamed to `config.excludeGroups`

Hardcoded defaults for `config.excludeGroups` and `config.excludeUsernames` have been removed, please review those fields if you provide your own exclusions.

## Upgrading from open source Kyverno to Nirmata Enterprise Subscription

If you are running open source Kyverno 1.10.0 or above in your cluster, you can directly upgrade to Nirmata Enterprise Subscription. E.g.

```console
helm upgrade kyverno --namespace kyverno nirmata/kyverno --set licenseManager.licenseKey=<license key >[,licenseManager.apiKey=<api key>]
```
If the helm install already had customizations, these too need to be provided to the above upgrade command as well, with a `-f <value override yaml>`. These parameters can be retrieved via
```console
helm get values kyverno -n kyverno
```

## Installing policies

You can install the curated Kyverno policies by following the instructions [here](https://github.com/nirmata/kyverno-policies)

## Uninstalling the Chart
To uninstall/delete the `kyverno` deployment:
```console
helm delete -n kyverno kyverno
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Uninstall manually installed Kyverno (YAML)

To uninstall/delete the `kyverno` deployment follow these steps:

```console
kubectl delete -f kyverno.yaml
```
Where kyverno.yaml is the one created when the `helm template` command was run. Ref: [Installing the YAML](#Installing-the-YAML)

You can check if any kyverno resources are still deployed using the commands:

```console
kubectl get crds |grep kyverno
kubectl get crds |grep policyreports
kubectl get clusterrole |grep kyverno
kubectl get clusterrolebinding |grep kyverno
```
## Values

The chart values are organised per component.

### Custom resource definitions

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| crds.annotations | object | `{}` | Additional CRDs annotations |
| crds.install | bool | `true` | Whether to have Helm install the Kyverno CRDs, if the CRDs are not installed by Helm, they must be added before policies can be created |

### Config

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| config.annotations | object | `{}` | Additional annotations to add to the configmap. |
| config.create | bool | `true` | Create the configmap. |
| config.defaultRegistry | string | `"docker.io"` | The registry hostname used for the image mutation. |
| config.enableDefaultRegistryMutation | bool | `true` | Enable registry mutation for container images. Enabled by default. |
| config.excludeClusterRoles | list | `[]` | Exclude roles |
| config.excludeGroups | list | `["system:nodes"]` | Exclude groups |
| config.excludeKyvernoNamespace | bool | `true` | Exclude Kyverno namespace Determines if default Kyverno namespace exclusion is enabled for webhooks and resourceFilters |
| config.excludeRoles | list | `[]` | Exclude roles |
| config.excludeUsernames | list | `[]` | Exclude usernames |
| config.generateSuccessEvents | bool | `false` | Generate success events. |
| config.name | string | `nil` | The configmap name (required if `create` is `false`). |
| config.resourceFilters | list | See [values.yaml](values.yaml) | Resource types to be skipped by the Kyverno policy engine. Make sure to surround each entry in quotes so that it doesn't get parsed as a nested YAML list. These are joined together without spaces, run through `tpl`, and the result is set in the config map. |
| config.resourceFiltersExcludeNamespaces | list | `[]` | resourceFilter namespace exclude Namespaces to exclude from the default resourceFilters |
| config.webhookAnnotations | object | `{}` | Defines annotations to set on webhook configurations. |
| config.webhooks | list | `[]` | Defines the `namespaceSelector` in the webhook configurations. Note that it takes a list of `namespaceSelector` and/or `objectSelector` in the JSON format, and only the first element will be forwarded to the webhook configurations. The Kyverno namespace is excluded if `excludeKyvernoNamespace` is `true` (default) |

### Metrics config

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| metricsConfig.annotations | object | `{}` | Additional annotations to add to the configmap. |
| metricsConfig.create | bool | `true` | Create the configmap. |
| metricsConfig.metricsRefreshInterval | string | `nil` | Rate at which metrics should reset so as to clean up the memory footprint of kyverno metrics, if you might be expecting high memory footprint of Kyverno's metrics. Default: 0, no refresh of metrics |
| metricsConfig.name | string | `nil` | The configmap name (required if `create` is `false`). |
| metricsConfig.namespaces.exclude | list | `[]` | list of namespaces to NOT capture metrics for. |
| metricsConfig.namespaces.include | list | `[]` | List of namespaces to capture metrics for. |

### Features

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| features.admissionReports.enabled | bool | `true` | Enables the feature |
| features.autoUpdateWebhooks.enabled | bool | `true` | Enables the feature |
| features.backgroundScan.backgroundScanInterval | string | `"1h"` | Background scan interval |
| features.backgroundScan.backgroundScanWorkers | int | `2` | Number of background scan workers |
| features.backgroundScan.enabled | bool | `true` | Enables the feature |
| features.backgroundScan.skipResourceFilters | bool | `true` | Skips resource filters in background scan |
| features.configMapCaching.enabled | bool | `true` | Enables the feature |
| features.deferredLoading.enabled | bool | `true` | Enables the feature |
| features.dumpPayload.enabled | bool | `false` | Enables the feature |
| features.forceFailurePolicyIgnore.enabled | bool | `false` | Enables the feature |
| features.logging.format | string | `"text"` | Logging format |
| features.logging.verbosity | int | `2` | Logging verbosity |
| features.omitEvents.eventTypes | list | `[]` | Events which should not be emitted (possible values `PolicyViolation`, `PolicyApplied`, `PolicyError`, and `PolicySkipped`) |
| features.policyExceptions.enabled | bool | `false` | Enables the feature |
| features.policyExceptions.namespace | string | `""` | Restrict policy exceptions to a single namespace |
| features.protectManagedResources.enabled | bool | `false` | Enables the feature |
| features.registryClient.allowInsecure | bool | `false` | Allow insecure registry |
| features.registryClient.credentialHelpers | list | `["default","google","amazon","azure","github"]` | Enable registry client helpers |
| features.reports.chunkSize | int | `1000` | Reports chunk size |

### Admission controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admissionController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| admissionController.container.extraArgs | object | `{}` | Additional container args. |
| admissionController.container.extraEnvVars | list | `[]` | Additional container environment variables. |
| admissionController.container.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| admissionController.container.image.registry | string | `"ghcr.io"` | Image registry |
| admissionController.container.image.repository | string | `"nirmata/kyverno"` | Image repository |
| admissionController.container.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| admissionController.container.resources.limits | object | `{"memory":"384Mi"}` | Pod resource limits |
| admissionController.container.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Pod resource requests |
| admissionController.container.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context |
| admissionController.createSelfSignedCert | bool | `false` | Create self-signed certificates at deployment time. The certificates won't be automatically renewed if this is set to `true`. |
| admissionController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| admissionController.extraContainers | list | `[]` | Array of extra containers to run alongside kyverno |
| admissionController.extraInitContainers | list | `[]` | Array of extra init containers |
| admissionController.featuresOverride | object | `{}` | Overrides features defined at the root level |
| admissionController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| admissionController.imagePullSecrets | list | `[]` | Image pull secrets |
| admissionController.initContainer.extraArgs | object | `{}` | Additional container args. |
| admissionController.initContainer.extraEnvVars | list | `[]` | Additional container environment variables. |
| admissionController.initContainer.image.pullPolicy | string | `nil` | Image pull policy If missing, defaults to image.pullPolicy |
| admissionController.initContainer.image.registry | string | `"ghcr.io"` | Image registry |
| admissionController.initContainer.image.repository | string | `"nirmata/kyvernopre"` | Image repository |
| admissionController.initContainer.image.tag | string | `nil` | Image tag If missing, defaults to image.tag |
| admissionController.initContainer.resources.limits | object | `{"cpu":"100m","memory":"256Mi"}` | Pod resource limits |
| admissionController.initContainer.resources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| admissionController.initContainer.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context |
| admissionController.livenessProbe | object | See [values.yaml](values.yaml) | Liveness probe. The block is directly forwarded into the deployment, so you can use whatever livenessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| admissionController.metering.collector | string | `""` | Otel collector endpoint |
| admissionController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| admissionController.metering.creds | string | `""` | Otel collector credentials |
| admissionController.metering.disabled | bool | `false` | Disable metrics export |
| admissionController.metering.port | int | `8000` | Prometheus endpoint port |
| admissionController.metricsService.annotations | object | `{}` | Service annotations. |
| admissionController.metricsService.create | bool | `true` | Create service. |
| admissionController.metricsService.nodePort | string | `nil` | Service node port. Only used if `type` is `NodePort`. |
| admissionController.metricsService.port | int | `8000` | Service port. Kyverno's metrics server will be exposed at this port. |
| admissionController.metricsService.type | string | `"ClusterIP"` | Service type. |
| admissionController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| admissionController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| admissionController.nodeAffinity | object | `{}` | Node affinity constraints. |
| admissionController.nodeSelector | object | `{}` | Node labels for pod assignment |
| admissionController.podAffinity | object | `{}` | Pod affinity constraints. |
| admissionController.podAnnotations | object | `{}` | Additional annotations to add to each pod |
| admissionController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| admissionController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| admissionController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| admissionController.podLabels | object | `{}` | Additional labels to add to each pod |
| admissionController.podSecurityContext | object | `{}` | Security context for the pod |
| admissionController.priorityClassName | string | `""` | Optional priority class |
| admissionController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| admissionController.rbac.create | bool | `true` | Create RBAC resources |
| admissionController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| admissionController.rbac.serviceAccount.name | string | `nil` | The ServiceAccount name |
| admissionController.readinessProbe | object | See [values.yaml](values.yaml) | Readiness Probe. The block is directly forwarded into the deployment, so you can use whatever readinessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| admissionController.replicas | int | `nil` | Desired number of pods |
| admissionController.service.annotations | object | `{}` | Service annotations. |
| admissionController.service.nodePort | string | `nil` | Service node port. Only used if `type` is `NodePort`. |
| admissionController.service.port | int | `443` | Service port. |
| admissionController.service.type | string | `"ClusterIP"` | Service type. |
| admissionController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| admissionController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| admissionController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| admissionController.serviceMonitor.metricRelabelings | list | `[]` | MetricRelabelConfigs to apply to samples before ingestion. |
| admissionController.serviceMonitor.namespace | string | `nil` | Override namespace |
| admissionController.serviceMonitor.relabelings | list | `[]` | RelabelConfigs to apply to samples before scraping |
| admissionController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| admissionController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| admissionController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| admissionController.sigstoreVolume | object | `{"emptyDir":{}}` | Volume to be mounted in pods for TUF/cosign work. |
| admissionController.startupProbe | object | See [values.yaml](values.yaml) | Startup probe. The block is directly forwarded into the deployment, so you can use whatever startupProbes configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| admissionController.tolerations | list | `[]` | List of node taints to tolerate |
| admissionController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| admissionController.tracing.address | string | `nil` | Traces receiver address |
| admissionController.tracing.creds | string | `""` | Traces receiver credentials |
| admissionController.tracing.enabled | bool | `false` | Enable tracing |
| admissionController.tracing.port | string | `nil` | Traces receiver port |
| admissionController.tufRootMountPath | string | `"/.sigstore"` | A writable volume to use for the TUF root initialization. |
| admissionController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |

### Background controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backgroundController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| backgroundController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| backgroundController.enabled | bool | `true` | Enable background controller. |
| backgroundController.extraArgs | object | `{}` | Extra arguments passed to the container on the command line |
| backgroundController.extraEnvVars | list | `[]` | Additional container environment variables. |
| backgroundController.featuresOverride | object | `{}` | Overrides features defined at the root level |
| backgroundController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| backgroundController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| backgroundController.image.registry | string | `"ghcr.io"` | Image registry |
| backgroundController.image.repository | string | `"nirmata/background-controller"` | Image repository |
| backgroundController.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| backgroundController.imagePullSecrets | list | `[]` | Image pull secrets |
| backgroundController.metering.collector | string | `""` | Otel collector endpoint |
| backgroundController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| backgroundController.metering.creds | string | `""` | Otel collector credentials |
| backgroundController.metering.disabled | bool | `false` | Disable metrics export |
| backgroundController.metering.port | int | `8000` | Prometheus endpoint port |
| backgroundController.metricsService.annotations | object | `{}` | Service annotations. |
| backgroundController.metricsService.create | bool | `true` | Create service. |
| backgroundController.metricsService.nodePort | string | `nil` | Service node port. Only used if `metricsService.type` is `NodePort`. |
| backgroundController.metricsService.port | int | `8000` | Service port. Metrics server will be exposed at this port. |
| backgroundController.metricsService.type | string | `"ClusterIP"` | Service type. |
| backgroundController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| backgroundController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| backgroundController.nodeAffinity | object | `{}` | Node affinity constraints. |
| backgroundController.nodeSelector | object | `{}` | Node labels for pod assignment |
| backgroundController.podAffinity | object | `{}` | Pod affinity constraints. |
| backgroundController.podAnnotations | object | `{}` | Additional annotations to add to each pod |
| backgroundController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| backgroundController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| backgroundController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| backgroundController.podLabels | object | `{}` | Additional labels to add to each pod |
| backgroundController.podSecurityContext | object | `{}` | Security context for the pod |
| backgroundController.priorityClassName | string | `""` | Optional priority class |
| backgroundController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| backgroundController.rbac.create | bool | `true` | Create RBAC resources |
| backgroundController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| backgroundController.rbac.serviceAccount.name | string | `nil` | Service account name |
| backgroundController.replicas | int | `nil` | Desired number of pods |
| backgroundController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| backgroundController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| backgroundController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| backgroundController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| backgroundController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| backgroundController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| backgroundController.serviceMonitor.metricRelabelings | list | `[]` | MetricRelabelConfigs to apply to samples before ingestion. |
| backgroundController.serviceMonitor.namespace | string | `nil` | Override namespace |
| backgroundController.serviceMonitor.relabelings | list | `[]` | RelabelConfigs to apply to samples before scraping |
| backgroundController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| backgroundController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| backgroundController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| backgroundController.tolerations | list | `[]` | List of node taints to tolerate |
| backgroundController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| backgroundController.tracing.address | string | `nil` | Traces receiver address |
| backgroundController.tracing.creds | string | `""` | Traces receiver credentials |
| backgroundController.tracing.enabled | bool | `false` | Enable tracing |
| backgroundController.tracing.port | string | `nil` | Traces receiver port |
| backgroundController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |

### Cleanup controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `nil` | Override the name of the chart |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| namespaceOverride | string | `nil` | Override the namespace the chart deploys to |
| apiVersionOverride.podDisruptionBudget | string | `nil` | Override api version used to create `PodDisruptionBudget`` resources. When not specified the chart will check if `policy/v1/PodDisruptionBudget` is available to determine the api version automatically. |
| crds.install | bool | `true` | Whether to have Helm install the Kyverno CRDs, if the CRDs are not installed by Helm, they must be added before policies can be created |
| crds.annotations | object | `{}` | Additional CRDs annotations |
| config.create | bool | `true` | Create the configmap. |
| config.name | string | `nil` | The configmap name (required if `create` is `false`). |
| config.annotations | object | `{}` | Additional annotations to add to the configmap. |
| config.enableDefaultRegistryMutation | bool | `true` | Enable registry mutation for container images. Enabled by default. |
| config.defaultRegistry | string | `"docker.io"` | The registry hostname used for the image mutation. |
| config.excludeGroups | list | `["system:serviceaccounts:kube-system","system:nodes"]` | Exclude groups |
| config.excludeUsernames | list | `[]` | Exclude usernames |
| config.excludeRoles | list | `[]` | Exclude roles |
| config.excludeClusterRoles | list | `[]` | Exclude roles |
| config.generateSuccessEvents | bool | `false` | Generate success events. |
| config.resourceFilters | list | See [values.yaml](values.yaml) | Resource types to be skipped by the Kyverno policy engine. Make sure to surround each entry in quotes so that it doesn't get parsed as a nested YAML list. These are joined together without spaces, run through `tpl`, and the result is set in the config map. |
| config.webhooks | list | `[]` | Defines the `namespaceSelector` in the webhook configurations. Note that it takes a list of `namespaceSelector` and/or `objectSelector` in the JSON format, and only the first element will be forwarded to the webhook configurations. The Kyverno namespace is excluded if `excludeKyvernoNamespace` is `true` (default) |
| config.webhookAnnotations | object | `{}` | Defines annotations to set on webhook configurations. |
| config.excludeKyvernoNamespace | bool | `true` | Exclude Kyverno namespace Determines if default Kyverno namespace exclusion is enabled for webhooks and resourceFilters |
| config.resourceFiltersExcludeNamespaces | list | `[]` | resourceFilter namespace exclude Namespaces to exclude from the default resourceFilters |
| metricsConfig.create | bool | `true` | Create the configmap. |
| metricsConfig.name | string | `nil` | The configmap name (required if `create` is `false`). |
| metricsConfig.annotations | object | `{}` | Additional annotations to add to the configmap. |
| metricsConfig.namespaces.include | list | `[]` | List of namespaces to capture metrics for. |
| metricsConfig.namespaces.exclude | list | `[]` | list of namespaces to NOT capture metrics for. |
| metricsConfig.metricsRefreshInterval | string | `nil` | Rate at which metrics should reset so as to clean up the memory footprint of kyverno metrics, if you might be expecting high memory footprint of Kyverno's metrics. Default: 0, no refresh of metrics |
| imagePullSecrets | object | `{}` | Image pull secrets for image verification policies, this will define the `--imagePullSecrets` argument |
| existingImagePullSecrets | list | `[]` | Existing Image pull secrets for image verification policies, this will define the `--imagePullSecrets` argument |
| test.image.registry | string | `nil` | Image registry |
| test.image.repository | string | `"busybox"` | Image repository |
| test.image.tag | string | `"1.35"` | Image tag Defaults to `latest` if omitted |
| test.image.pullPolicy | string | `nil` | Image pull policy Defaults to image.pullPolicy if omitted |
| test.resources.limits | object | `{"cpu":"100m","memory":"256Mi"}` | Pod resource limits |
| test.resources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| test.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":65534,"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the test containers |
| customLabels | object | `{}` | Additional labels |
| webhooksCleanup.enabled | bool | `false` | Create a helm pre-delete hook to cleanup webhooks. |
| webhooksCleanup.image | string | `"bitnami/kubectl:latest"` | `kubectl` image to run commands for deleting webhooks. |
| tufRootMountPath | string | `"/.sigstore"` | A writable volume to use for the TUF root initialization. |
| customCAConfigMap | string | | Configmap storing custom CA certificate |
| systemCertPath | string | `/etc/ssl/certs` | Path containing ssl certs within the container. Used only if customCAConfigMap is used |
| licenceManager.enable | bool | `true` | Whether to use license manager |
| licenceManager.imageRepository | string | `ghcr.io/nirmata/kyverno-license-manager` | License manager repository |
| licenceManager.imageTag | string | `v0.1.2` | License manager image tag |
| licenceManager.productName | string | | Product name to be present in license, ignore product name check if empty |
| licenceManager.validateIntervalMins | int | `60` | License validation interval in mins|
| licenceManager.callHomeServer | string | `nirmata.io` | License server hostname:port |
| licenceManager.licenseKey | string | `free-tier-license` | License key (required) |
| licenceManager.apiKey | string | | License server API key |
| licenceManager.clusterId | string | | Cluster Id to use. If not provided, uid of kube-system namnespace |
| licenceManager.clusterName | string | | Cluster Name to use. Auto-generated if not provided |
| grafana.enabled | bool | `false` | Enable grafana dashboard creation. |
| grafana.configMapName | string | `"{{ include \"kyverno.fullname\" . }}-grafana"` | Configmap name template. |
| grafana.namespace | string | `nil` | Namespace to create the grafana dashboard configmap. If not set, it will be created in the same namespace where the chart is deployed. |
| grafana.annotations | object | `{}` | Grafana dashboard configmap annotations. |
| admissionController.rbac.create | bool | `true` | Create RBAC resources |
| admissionController.rbac.serviceAccount.name | string | `nil` | The ServiceAccount name |
| admissionController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| admissionController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| admissionController.createSelfSignedCert | bool | `false` | Create self-signed certificates at deployment time. The certificates won't be automatically renewed if this is set to `true`. |
| admissionController.replicas | int | `nil` | Desired number of pods |
| admissionController.podLabels | object | `{}` | Additional labels to add to each pod |
| admissionController.podAnnotations | object | `{}` | Additional annotations to add to each pod |
| admissionController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| admissionController.priorityClassName | string | `""` | Optional priority class |
| admissionController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| admissionController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| admissionController.startupProbe | object | See [values.yaml](values.yaml) | Startup probe. The block is directly forwarded into the deployment, so you can use whatever startupProbes configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| admissionController.livenessProbe | object | See [values.yaml](values.yaml) | Liveness probe. The block is directly forwarded into the deployment, so you can use whatever livenessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| admissionController.readinessProbe | object | See [values.yaml](values.yaml) | Readiness Probe. The block is directly forwarded into the deployment, so you can use whatever readinessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| admissionController.nodeSelector | object | `{}` | Node labels for pod assignment |
| admissionController.tolerations | list | `[]` | List of node taints to tolerate |
| admissionController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| admissionController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| admissionController.podAffinity | object | `{}` | Pod affinity constraints. |
| admissionController.nodeAffinity | object | `{}` | Node affinity constraints. |
| admissionController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| admissionController.podSecurityContext | object | `{}` | Security context for the pod |
| admissionController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| admissionController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| admissionController.tufRootMountPath | string | `"/.sigstore"` | A writable volume to use for the TUF root initialization. |
| admissionController.sigstoreVolume | object | `{"emptyDir":{}}` | Volume to be mounted in pods for TUF/cosign work. |
| admissionController.imagePullSecrets | list | `[]` | Image pull secrets |
| admissionController.initContainer.image.registry | string | `"ghcr.io"` | Image registry |
| admissionController.initContainer.image.repository | string | `"nirmata/kyvernopre"` | Image repository |
| admissionController.initContainer.image.tag | string | `nil` | Image tag If missing, defaults to image.tag |
| admissionController.initContainer.image.pullPolicy | string | `nil` | Image pull policy If missing, defaults to image.pullPolicy |
| admissionController.initContainer.resources.limits | object | `{"cpu":"100m","memory":"256Mi"}` | Pod resource limits |
| admissionController.initContainer.resources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| admissionController.initContainer.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context |
| admissionController.initContainer.extraArgs | object | `{}` | Additional container args. |
| admissionController.initContainer.extraEnvVars | list | `[]` | Additional container environment variables. |
| admissionController.container.image.registry | string | `"ghcr.io"` | Image registry |
| admissionController.container.image.repository | string | `"nirmata/kyverno"` | Image repository |
| admissionController.container.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| admissionController.container.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| admissionController.container.resources.limits | object | `{"memory":"384Mi"}` | Pod resource limits |
| admissionController.container.resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Pod resource requests |
| admissionController.container.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context |
| admissionController.container.extraArgs | object | `{}` | Additional container args. |
| admissionController.container.extraEnvVars | list | `[]` | Additional container environment variables. |
| admissionController.extraInitContainers | list | `[]` | Array of extra init containers |
| admissionController.extraContainers | list | `[]` | Array of extra containers to run alongside kyverno |
| admissionController.service.port | int | `443` | Service port. |
| admissionController.service.type | string | `"ClusterIP"` | Service type. |
| admissionController.service.nodePort | string | `nil` | Service node port. Only used if `type` is `NodePort`. |
| admissionController.service.annotations | object | `{}` | Service annotations. |
| admissionController.metricsService.create | bool | `true` | Create service. |
| admissionController.metricsService.port | int | `8000` | Service port. Kyverno's metrics server will be exposed at this port. |
| admissionController.metricsService.type | string | `"ClusterIP"` | Service type. |
| admissionController.metricsService.nodePort | string | `nil` | Service node port. Only used if `type` is `NodePort`. |
| admissionController.metricsService.annotations | object | `{}` | Service annotations. |
| admissionController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| admissionController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| admissionController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| admissionController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| admissionController.serviceMonitor.namespace | string | `nil` | Override namespace |
| admissionController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| admissionController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| admissionController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| admissionController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| admissionController.tracing.enabled | bool | `false` | Enable tracing |
| admissionController.tracing.address | string | `nil` | Traces receiver address |
| admissionController.tracing.port | string | `nil` | Traces receiver port |
| admissionController.tracing.creds | string | `""` | Traces receiver credentials |
| admissionController.logging.format | string | `"text"` | Logging format |
| admissionController.metering.disabled | bool | `false` | Disable metrics export |
| admissionController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| admissionController.metering.port | int | `8000` | Prometheus endpoint port |
| admissionController.metering.collector | string | `""` | Otel collector endpoint |
| admissionController.metering.creds | string | `""` | Otel collector credentials |
| cleanupController.enabled | bool | `true` | Enable cleanup controller. |
| cleanupController.rbac.create | bool | `true` | Create RBAC resources |
| cleanupController.rbac.serviceAccount.name | string | `nil` | Service account name |
| cleanupController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| cleanupController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| cleanupController.createSelfSignedCert | bool | `false` | Create self-signed certificates at deployment time. The certificates won't be automatically renewed if this is set to `true`. |
| cleanupController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| cleanupController.enabled | bool | `true` | Enable cleanup controller. |
| cleanupController.extraArgs | object | `{}` | Extra arguments passed to the container on the command line |
| cleanupController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| cleanupController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| cleanupController.startupProbe | object | See [values.yaml](values.yaml) | Startup probe. The block is directly forwarded into the deployment, so you can use whatever startupProbes configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.livenessProbe | object | See [values.yaml](values.yaml) | Liveness probe. The block is directly forwarded into the deployment, so you can use whatever livenessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.metering.collector | string | `""` | Otel collector endpoint |
| cleanupController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| cleanupController.metering.creds | string | `""` | Otel collector credentials |
| cleanupController.metering.disabled | bool | `false` | Disable metrics export |
| cleanupController.metering.port | int | `8000` | Prometheus endpoint port |
| cleanupController.metricsService.annotations | object | `{}` | Service annotations. |
| cleanupController.metricsService.create | bool | `true` | Create service. |
| cleanupController.metricsService.nodePort | string | `nil` | Service node port. Only used if `metricsService.type` is `NodePort`. |
| cleanupController.metricsService.port | int | `8000` | Service port. Metrics server will be exposed at this port. |
| cleanupController.metricsService.type | string | `"ClusterIP"` | Service type. |
| cleanupController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| cleanupController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| cleanupController.nodeAffinity | object | `{}` | Node affinity constraints. |
| cleanupController.nodeSelector | object | `{}` | Node labels for pod assignment |
| cleanupController.podAffinity | object | `{}` | Pod affinity constraints. |
| cleanupController.podAnnotations | object | `{}` | Additional annotations to add to each pod |
| cleanupController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| cleanupController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| cleanupController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| cleanupController.podLabels | object | `{}` | Additional labels to add to each pod |
| cleanupController.podSecurityContext | object | `{}` | Security context for the pod |
| cleanupController.priorityClassName | string | `""` | Optional priority class |
| cleanupController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| cleanupController.rbac.create | bool | `true` | Create RBAC resources |
| cleanupController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| cleanupController.rbac.serviceAccount.name | string | `nil` | Service account name |
| cleanupController.readinessProbe | object | See [values.yaml](values.yaml) | Readiness Probe. The block is directly forwarded into the deployment, so you can use whatever readinessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.replicas | int | `nil` | Desired number of pods |
| cleanupController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| cleanupController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| cleanupController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| cleanupController.service.annotations | object | `{}` | Service annotations. |
| cleanupController.service.nodePort | string | `nil` | Service node port. Only used if `service.type` is `NodePort`. |
| cleanupController.service.port | int | `443` | Service port. |
| cleanupController.service.type | string | `"ClusterIP"` | Service type. |
| cleanupController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| cleanupController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| cleanupController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| cleanupController.serviceMonitor.metricRelabelings | list | `[]` | MetricRelabelConfigs to apply to samples before ingestion. |
| cleanupController.serviceMonitor.namespace | string | `nil` | Override namespace |
| cleanupController.serviceMonitor.relabelings | list | `[]` | RelabelConfigs to apply to samples before scraping |
| cleanupController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| cleanupController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| cleanupController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| cleanupController.startupProbe | object | See [values.yaml](values.yaml) | Startup probe. The block is directly forwarded into the deployment, so you can use whatever startupProbes configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.tolerations | list | `[]` | List of node taints to tolerate |
| cleanupController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| cleanupController.tracing.address | string | `nil` | Traces receiver address |
| cleanupController.tracing.creds | string | `""` | Traces receiver credentials |
| cleanupController.metering.disabled | bool | `false` | Disable metrics export |
| cleanupController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| cleanupController.metering.port | int | `8000` | Prometheus endpoint port |
| cleanupController.metering.collector | string | `""` | Otel collector endpoint |
| cleanupController.metering.creds | string | `""` | Otel collector credentials |
| reportsController.enabled | bool | `true` | Enable reports controller. |
| reportsController.rbac.create | bool | `true` | Create RBAC resources |
| reportsController.rbac.serviceAccount.name | string | `nil` | Service account name |
| reportsController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| reportsController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| reportsController.image.registry | string | `"ghcr.io"` | Image registry |
| reportsController.image.repository | string | `"kyverno/reports-controller"` | Image repository |
| reportsController.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| reportsController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| reportsController.imagePullSecrets | list | `[]` | Image pull secrets |
| reportsController.replicas | int | `nil` | Desired number of pods |
| reportsController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| reportsController.priorityClassName | string | `""` | Optional priority class |
| reportsController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| reportsController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| reportsController.extraArgs | object | `{"clientRateLimitBurst":300,"clientRateLimitQPS":300,"skipResourceFilters":true}` | Extra arguments passed to the container on the command line |
| reportsController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| reportsController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| reportsController.nodeSelector | object | `{}` | Node labels for pod assignment |
| reportsController.tolerations | list | `[]` | List of node taints to tolerate |
| reportsController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| reportsController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| reportsController.podAffinity | object | `{}` | Pod affinity constraints. |
| reportsController.nodeAffinity | object | `{}` | Node affinity constraints. |
| reportsController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| reportsController.podSecurityContext | object | `{}` | Security context for the pod |
| reportsController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| reportsController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| reportsController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| reportsController.tufRootMountPath | string | `"/.sigstore"` | A writable volume to use for the TUF root initialization. |
| reportsController.sigstoreVolume | object | `{"emptyDir":{}}` | Volume to be mounted in pods for TUF/cosign work. |
| reportsController.metricsService.create | bool | `true` | Create service. |
| reportsController.metricsService.port | int | `8000` | Service port. Metrics server will be exposed at this port. |
| reportsController.metricsService.type | string | `"ClusterIP"` | Service type. |
| reportsController.metricsService.nodePort | string | `nil` | Service node port. Only used if `type` is `NodePort`. |
| reportsController.metricsService.annotations | object | `{}` | Service annotations. |
| reportsController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| reportsController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| reportsController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| reportsController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| reportsController.serviceMonitor.namespace | string | `nil` | Override namespace |
| reportsController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| reportsController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| reportsController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| reportsController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| reportsController.tracing.enabled | bool | `false` | Enable tracing |
| reportsController.tracing.address | string | `nil` | Traces receiver address |
| reportsController.tracing.port | string | `nil` | Traces receiver port |
| reportsController.tracing.creds | string | `nil` | Traces receiver credentials |
| reportsController.logging.format | string | `"text"` | Logging format |
| reportsController.metering.disabled | bool | `false` | Disable metrics export |
| reportsController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| reportsController.metering.port | int | `8000` | Prometheus endpoint port |
| reportsController.metering.collector | string | `nil` | Otel collector endpoint |
| reportsController.metering.creds | string | `nil` | Otel collector credentials |
| backgroundController.enabled | bool | `true` | Enable background controller. |
| backgroundController.rbac.create | bool | `true` | Create RBAC resources |
| backgroundController.rbac.serviceAccount.name | string | `nil` | Service account name |
| backgroundController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| backgroundController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| backgroundController.image.registry | string | `nil` | Image registry |
| backgroundController.image.repository | string | `"ghcr.io/nirmata/background-controller"` | Image repository |
| backgroundController.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| backgroundController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| backgroundController.imagePullSecrets | list | `[]` | Image pull secrets |
| backgroundController.replicas | int | `nil` | Desired number of pods |
| backgroundController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| backgroundController.priorityClassName | string | `""` | Optional priority class |
| backgroundController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| backgroundController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| backgroundController.extraArgs | object | `{}` | Extra arguments passed to the container on the command line |
| backgroundController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| backgroundController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| backgroundController.nodeSelector | object | `{}` | Node labels for pod assignment |
| backgroundController.tolerations | list | `[]` | List of node taints to tolerate |
| backgroundController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| backgroundController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| backgroundController.podAffinity | object | `{}` | Pod affinity constraints. |
| backgroundController.nodeAffinity | object | `{}` | Node affinity constraints. |
| backgroundController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| backgroundController.podSecurityContext | object | `{}` | Security context for the pod |
| backgroundController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| backgroundController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| backgroundController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| backgroundController.metricsService.create | bool | `true` | Create service. |
| backgroundController.metricsService.port | int | `8000` | Service port. Metrics server will be exposed at this port. |
| backgroundController.metricsService.type | string | `"ClusterIP"` | Service type. |
| backgroundController.metricsService.nodePort | string | `nil` | Service node port. Only used if `metricsService.type` is `NodePort`. |
| backgroundController.metricsService.annotations | object | `{}` | Service annotations. |
| backgroundController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| backgroundController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| backgroundController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| backgroundController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| backgroundController.serviceMonitor.namespace | string | `nil` | Override namespace |
| backgroundController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| backgroundController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| backgroundController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| backgroundController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| backgroundController.tracing.enabled | bool | `false` | Enable tracing |
| backgroundController.tracing.address | string | `nil` | Traces receiver address |
| backgroundController.tracing.port | string | `nil` | Traces receiver port |
| backgroundController.tracing.creds | string | `""` | Traces receiver credentials |
| backgroundController.logging.format | string | `"text"` | Logging format |
| backgroundController.metering.disabled | bool | `false` | Disable metrics export |
| backgroundController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| backgroundController.metering.port | int | `8000` | Prometheus endpoint port |
| backgroundController.metering.collector | string | `""` | Otel collector endpoint |
| backgroundController.metering.creds | string | `""` | Otel collector credentials |
| licenceManager.enable | bool | `true` | Whether to use license manager |
| licenceManager.imageRepository | string | `ghcr.io/nirmata/kyverno-license-manager` | License manager repository |
| licenceManager.imageTag | string | `v0.0.1` | License manager image tag |
| licenceManager.productName | string | | Product name to be present in license, ignore product name check if empty |
| licenceManager.validateIntervalMins | int | `60` | License validation interval in mins|
| licenceManager.callHomeServer | string | `nirmata.io` | License server hostname:port |
| licenceManager.licenseKey | string | | License key (required) |
| licenceManager.apiKey | string | | License server API key |
| licenceManager.clusterId | string | | Cluster Id to use. If not provided, uid of kube-system namnespace |
| licenceManager.clusterName | string | | Cluster Name to use. Auto-generated if not provided |

### Reports controller

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| reportsController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| reportsController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| reportsController.enabled | bool | `true` | Enable reports controller. |
| reportsController.extraArgs | object | `{}` | Extra arguments passed to the container on the command line |
| reportsController.extraEnvVars | list | `[]` | Additional container environment variables. |
| reportsController.featuresOverride | object | `{}` | Overrides features defined at the root level |
| reportsController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| reportsController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| reportsController.image.registry | string | `"ghcr.io"` | Image registry |
| reportsController.image.repository | string | `"nirmata/reports-controller"` | Image repository |
| reportsController.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| reportsController.imagePullSecrets | list | `[]` | Image pull secrets |
| reportsController.metering.collector | string | `nil` | Otel collector endpoint |
| reportsController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| reportsController.metering.creds | string | `nil` | Otel collector credentials |
| reportsController.metering.disabled | bool | `false` | Disable metrics export |
| reportsController.metering.port | int | `8000` | Prometheus endpoint port |
| reportsController.metricsService.annotations | object | `{}` | Service annotations. |
| reportsController.metricsService.create | bool | `true` | Create service. |
| reportsController.metricsService.nodePort | string | `nil` | Service node port. Only used if `type` is `NodePort`. |
| reportsController.metricsService.port | int | `8000` | Service port. Metrics server will be exposed at this port. |
| reportsController.metricsService.type | string | `"ClusterIP"` | Service type. |
| reportsController.networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| reportsController.networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| reportsController.nodeAffinity | object | `{}` | Node affinity constraints. |
| reportsController.nodeSelector | object | `{}` | Node labels for pod assignment |
| reportsController.podAffinity | object | `{}` | Pod affinity constraints. |
| reportsController.podAnnotations | object | `{}` | Additional annotations to add to each pod |
| reportsController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| reportsController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| reportsController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| reportsController.podLabels | object | `{}` | Additional labels to add to each pod |
| reportsController.podSecurityContext | object | `{}` | Security context for the pod |
| reportsController.priorityClassName | string | `""` | Optional priority class |
| reportsController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| reportsController.rbac.create | bool | `true` | Create RBAC resources |
| reportsController.rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| reportsController.rbac.serviceAccount.name | string | `nil` | Service account name |
| reportsController.replicas | int | `nil` | Desired number of pods |
| reportsController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| reportsController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| reportsController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| reportsController.serviceMonitor.additionalLabels | object | `{}` | Additional labels |
| reportsController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| reportsController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| reportsController.serviceMonitor.metricRelabelings | list | `[]` | MetricRelabelConfigs to apply to samples before ingestion. |
| reportsController.serviceMonitor.namespace | string | `nil` | Override namespace |
| reportsController.serviceMonitor.relabelings | list | `[]` | RelabelConfigs to apply to samples before scraping |
| reportsController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| reportsController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| reportsController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| reportsController.sigstoreVolume | object | `{"emptyDir":{}}` | Volume to be mounted in pods for TUF/cosign work. |
| reportsController.tolerations | list | `[]` | List of node taints to tolerate |
| reportsController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| reportsController.tracing.address | string | `nil` | Traces receiver address |
| reportsController.tracing.creds | string | `nil` | Traces receiver credentials |
| reportsController.tracing.enabled | bool | `false` | Enable tracing |
| reportsController.tracing.port | string | `nil` | Traces receiver port |
| reportsController.tufRootMountPath | string | `"/.sigstore"` | A writable volume to use for the TUF root initialization. |
| reportsController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |

### Grafana

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| grafana.annotations | object | `{}` | Grafana dashboard configmap annotations. |
| grafana.configMapName | string | `"{{ include \"kyverno.fullname\" . }}-grafana"` | Configmap name template. |
| grafana.enabled | bool | `false` | Enable grafana dashboard creation. |
| grafana.labels | object | `{"grafana_dashboard":"1"}` | Grafana dashboard configmap labels |
| grafana.namespace | string | `nil` | Namespace to create the grafana dashboard configmap. If not set, it will be created in the same namespace where the chart is deployed. |

### Webhooks cleanup

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| webhooksCleanup.enabled | bool | `true` | Create a helm pre-delete hook to cleanup webhooks. |
| webhooksCleanup.image | string | `"bitnami/kubectl:latest"` | `kubectl` image to run commands for deleting webhooks. |
| webhooksCleanup.imagePullSecrets | list | `[]` | Image pull secrets |

### Test

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| test.image.pullPolicy | string | `nil` | Image pull policy Defaults to image.pullPolicy if omitted |
| test.image.registry | string | `nil` | Image registry |
| test.image.repository | string | `"busybox"` | Image repository |
| test.image.tag | string | `"1.35"` | Image tag Defaults to `latest` if omitted |
| test.resources.limits | object | `{"cpu":"100m","memory":"256Mi"}` | Pod resource limits |
| test.resources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| test.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":65534,"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the test containers |

### Api version override

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| apiVersionOverride.podDisruptionBudget | string | `nil` | Override api version used to create `PodDisruptionBudget`` resources. When not specified the chart will check if `policy/v1/PodDisruptionBudget` is available to determine the api version automatically. |

### Cleanup jobs

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cleanupJobs.admissionReports.enabled | bool | `true` | Enable cleanup cronjob |
| cleanupJobs.admissionReports.history | object | `{"failure":1,"success":1}` | Cronjob history |
| cleanupJobs.admissionReports.image.pullPolicy | string | `nil` | Image pull policy Defaults to image.pullPolicy if omitted |
| cleanupJobs.admissionReports.image.registry | string | `nil` | Image registry |
| cleanupJobs.admissionReports.image.repository | string | `"bitnami/kubectl"` | Image repository |
| cleanupJobs.admissionReports.image.tag | string | `"1.26.4"` | Image tag Defaults to `latest` if omitted |
| cleanupJobs.admissionReports.imagePullSecrets | list | `[]` | Image pull secrets |
| cleanupJobs.admissionReports.podAnnotations | object | `{}` | Pod Annotations |
| cleanupJobs.admissionReports.podSecurityContext | object | `{}` | Security context for the pod |
| cleanupJobs.admissionReports.resources | object | `{}` | Job resources |
| cleanupJobs.admissionReports.schedule | string | `"*/10 * * * *"` | Cronjob schedule |
| cleanupJobs.admissionReports.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| cleanupJobs.admissionReports.threshold | int | `10000` | Reports threshold, if number of reports are above this value the cronjob will start deleting them |
| cleanupJobs.admissionReports.tolerations | list | `[]` | List of node taints to tolerate |
| cleanupJobs.clusterAdmissionReports.enabled | bool | `true` | Enable cleanup cronjob |
| cleanupJobs.clusterAdmissionReports.history | object | `{"failure":1,"success":1}` | Cronjob history |
| cleanupJobs.clusterAdmissionReports.image.pullPolicy | string | `nil` | Image pull policy Defaults to image.pullPolicy if omitted |
| cleanupJobs.clusterAdmissionReports.image.registry | string | `nil` | Image registry |
| cleanupJobs.clusterAdmissionReports.image.repository | string | `"bitnami/kubectl"` | Image repository |
| cleanupJobs.clusterAdmissionReports.image.tag | string | `"1.26.4"` | Image tag Defaults to `latest` if omitted |
| cleanupJobs.clusterAdmissionReports.imagePullSecrets | list | `[]` | Image pull secrets |
| cleanupJobs.clusterAdmissionReports.podAnnotations | object | `{}` | Pod Annotations |
| cleanupJobs.clusterAdmissionReports.podSecurityContext | object | `{}` | Security context for the pod |
| cleanupJobs.clusterAdmissionReports.resources | object | `{}` | Job resources |
| cleanupJobs.clusterAdmissionReports.schedule | string | `"*/10 * * * *"` | Cronjob schedule |
| cleanupJobs.clusterAdmissionReports.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| cleanupJobs.clusterAdmissionReports.threshold | int | `10000` | Reports threshold, if number of reports are above this value the cronjob will start deleting them |
| cleanupJobs.clusterAdmissionReports.tolerations | list | `[]` | List of node taints to tolerate |

### Related to N4K Licensing and airgapped environments

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| licenseManager.apiKey | string | `nil` | License server API key |
| licenseManager.callHomeServer | string | `"nirmata.io"` | License server |
| licenseManager.clusterId | string | `nil` | Cluster Id. If not provided, use kube-system uid |
| licenseManager.clusterName | string | `nil` | Cluster name. Autogenerated if not provided |
| licenseManager.enable | bool | `true` | Whether to use license manager |
| licenseManager.imageRepository | string | `"ghcr.io/nirmata/kyverno-license-manager"` | License manager repo |
| licenseManager.imageTag | string | `"v0.0.2"` | Image tag |
| licenseManager.licenseKey | string | `nil` | License key |
| licenseManager.productName | string | `""` | Product name to be present in license, empty to ignore check |
| licenseManager.validateIntervalMins | int | `60` | Validation interval in mins |

### Other

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| customCAConfigMap | string | `nil` |  |
| customLabels | object | `{"app":"kyverno"}` | Additional labels |
| existingImagePullSecrets | list | `[]` | Existing Image pull secrets for image verification policies, this will define the `--imagePullSecrets` argument |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| imagePullSecrets | object | `{}` | Image pull secrets for image verification policies, this will define the `--imagePullSecrets` argument |
| nameOverride | string | `nil` | Override the name of the chart |
| namespaceOverride | string | `nil` | Override the namespace the chart deploys to |
| systemCertPath | string | `"/etc/ssl/certs"` |  |
| upgrade.fromV2 | bool | `false` | Upgrading from v2 to v3 is not allowed by default, set this to true once changes have been reviewed. |

## Specify parameters at Helm commandline
Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
helm install --namespace kyverno kyverno ./charts/kyverno \
  --set=image.tag=v0.0.2,resources.limits.cpu=200m
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
helm install --namespace kyverno kyverno ./charts/kyverno -f values.yaml
```

> **Tip**: You can use the default [values.yaml](values.yaml)

## TLS Configuration

If `admissionController.createSelfSignedCert` is `true`, Helm will take care of the steps of creating an external self-signed certificate described in option 2 of the [installation documentation](https://kyverno.io/docs/installation/#option-2-use-your-own-ca-signed-certificate)

If `admissionController.createSelfSignedCert` is `false`, Kyverno will generate a self-signed CA and a certificate, or you can provide your own TLS CA and signed-key pair and create the secret yourself as described in the [documentation](https://kyverno.io/docs/installation/#customize-the-installation-of-kyverno).

## Default resource filters

[Kyverno resource filters](https://kyverno.io/docs/installation/#resource-filters) are a used to exclude resources from the Kyverno engine rules processing.

This chart comes with default resource filters that apply exclusions on a couple of namespaces and resource kinds:
- all resources in `kube-system`, `kube-public` and `kube-node-lease` namespaces
- all resources in all namespaces for the following resource kinds:
  - `Event`
  - `Node`
  - `APIService`
  - `TokenReview`
  - `SubjectAccessReview`
  - `SelfSubjectAccessReview`
  - `Binding`
  - `ReplicaSet`
  - `AdmissionReport`
  - `ClusterAdmissionReport`
  - `BackgroundScanReport`
  - `ClusterBackgroundScanReport`
- all resources created by this chart itself

Those default exclusions are there to prevent disruptions as much as possible.
Under the hood, Kyverno installs an admission controller for critical cluster resources.
A cluster can become unresponsive if Kyverno is not up and running, ultimately preventing pods to be scheduled in the cluster.

You can however override the default resource filters by setting the `config.resourceFilters` stanza.
It contains an array of string templates that are passed through the `tpl` Helm function and joined together to produce the final `resourceFilters` written in the Kyverno config map.

Please consult the [values.yaml](./values.yaml) file before overriding `config.resourceFilters` and use the apropriate templates to build your desired exclusions list.

## High availability

Running a highly-available Kyverno installation is crucial in a production environment.

In order to run Kyverno in high availability mode, you should set `replicaCount` to `3` or more.
You should also pay attention to anti affinity rules, spreading pods across nodes and availability zones.

Please see https://kyverno.io/docs/installation/#security-vs-operability for more informations.

## Source Code

* <https://github.com/nirmata/kyverno>

## Requirements

Kubernetes: `>=1.16.0-0`
