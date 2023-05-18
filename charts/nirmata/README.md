# Kyverno

Kubernetes Native Policy Management

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
## Prerequisite

### Get license key
You need a license key to run Kyverno. If you are using Nirmata Enterprise for Kyverno, it is available in the UI. Else contact <support@nirmata.com>.

## Manage Kyverno through new Enterprise Kyverno Operator
Install the Enterprise Kyverno Operator following instructions [here](https://github.com/nirmata/kyverno-charts/blob/main/charts/enterprise-kyverno-operator/README.md). The operator will manage Kyverno lifecycle.

## (DEPRECATED) Independent Kyverno install with legacy Kyverno Operator
We recommend managing Kyverno lifecycle through the Enterprise Kyverno Operator mentioned above. This section is for users using the legacy operator and managing Kyverno directly through its Helm Chart.

**Install legacy Kyverno Operator**
Install the legacy Kyverno Operator following instructions [here](https://github.com/nirmata/kyverno-charts/blob/main/charts/kyverno-operator/README.md).

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


## Upgrading from open source Kyverno to Nirmata Enterprise Subscription

If you are running open source Kyverno 1.5.0 or above in your cluster, you can directly upgrade to Nirmata Enterprise Subscription

```console
helm upgrade kyverno --namespace kyverno nirmata/kyverno --set licenseManager.licenseKey=<license key >[,licenseManager.apiKey=<api key>]
```

## Installing policies

You can install the curated Kyverno policies by following the instructions [here](https://github.com/nirmata/kyverno-policies)

## Uninstalling the Chart
To uninstall/delete the `kyverno-operator` deployment:
```console
helm delete -n nirmata-kyverno-operator kyverno-operator
```

To uninstall/delete the `kyverno` deployment:

```console
helm delete -n kyverno kyverno
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Uninstall manually installed Kyverno (YAML)

To uninstall/delete the `kyverno` deployment follow these steps:

```console
kubectl delete deployment kyverno
kubectl delete crds clusterpolicies.kyverno.io clusterpolicyreports.wgpolicyk8s.io clusterreportchangerequests.kyverno.io generaterequests.kyverno.io policies.kyverno.io policyreports.wgpolicyk8s.io reportchangerequests.kyverno.io
kubectl delete clusterrole kyverno:admin-policies kyverno:admin-policyreport kyverno:admin-reportchangerequest kyverno:customresources kyverno:generatecontroller kyverno:leaderelection kyverno:policycontroller kyverno:userinfo kyverno:webhook
kubectl delete clusterrolebinding kyverno:customresources kyverno:generatecontroller kyverno:leaderelection kyverno:nirmata-ns-access-controls kyverno:policycontroller kyverno:userinfo kyverno:webhook
```

You can check if any kyverno resources are still deployed using the commands:

```console
kubectl get crds |grep kyverno
kubectl get crds |grep policyreports
kubectl get clusterrole |grep kyverno
kubectl get clusterrolebinding |grep kyverno
```

## Configuration

The following table lists the configurable parameters of the kyverno chart and their default values.

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `nil` | Override the name of the chart |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| namespace | string | `nil` | Namespace the chart deploys to |
| customLabels | object | `{}` | Additional labels |
| rbac.create | bool | `true` | Create ClusterRoles, ClusterRoleBindings, and ServiceAccount |
| rbac.serviceAccount.create | bool | `true` | Create a ServiceAccount |
| rbac.serviceAccount.name | string | `nil` | The ServiceAccount name |
| rbac.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| image.registry | string | `nil` | Image registry |
| image.repository | string | `"ghcr.io/kyverno/kyverno"` | Image repository |
| image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.pullSecrets | list | `[]` | Image pull secrets |
| initImage.registry | string | `nil` | Image registry |
| initImage.repository | string | `"ghcr.io/kyverno/kyvernopre"` | Image repository |
| initImage.tag | string | `nil` | Image tag If initImage.tag is missing, defaults to image.tag |
| initImage.pullPolicy | string | `nil` | Image pull policy If initImage.pullPolicy is missing, defaults to image.pullPolicy |
| initContainer.extraArgs | list | `["--loggingFormat=text"]` | Extra arguments to give to the kyvernopre binary. |
| testImage.registry | string | `nil` | Image registry |
| testImage.repository | string | `"busybox"` | Image repository |
| testImage.tag | float | `1.35` | Image tag Defaults to `latest` if omitted |
| testImage.pullPolicy | string | `nil` | Image pull policy Defaults to image.pullPolicy if omitted |
| replicaCount | int | `nil` | Desired number of pods |
| podLabels | object | `{}` | Additional labels to add to each pod |
| podAnnotations | object | `{}` | Additional annotations to add to each pod |
| podSecurityContext | object | `{}` | Security context for the pod |
| securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| testSecurityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsGroup":65534,"runAsNonRoot":true,"runAsUser":65534,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the test containers |
| priorityClassName | string | `""` | Optional priority class to be used for kyverno pods |
| antiAffinity.enable | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| podAffinity | object | `{}` | Pod affinity constraints. |
| nodeAffinity | object | `{}` | Node affinity constraints. |
| podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for kyverno disruptions. Cannot be used if `maxUnavailable` is set. |
| podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for kyverno disruptions. Cannot be used if `minAvailable` is set. |
| nodeSelector | object | `{}` | Node labels for pod assignment |
| tolerations | list | `[]` | List of node taints to tolerate |
| hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the kyverno's pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| envVarsInit | object | `{}` | Env variables for initContainers. |
| envVars | object | `{}` | Env variables for containers. |
| extraArgs | list | `["--loggingFormat=text","--exceptionNamespace={{ include \"kyverno.namespace\" . }}"]` | Extra arguments to give to the binary. |
| extraInitContainers | list | `[]` | Array of extra init containers |
| extraContainers | list | `[]` | Array of extra containers to run alongside kyverno |
| imagePullSecrets | object | `{}` | Image pull secrets for image verify and imageData policies. This will define the `--imagePullSecrets` Kyverno argument. |
| existingImagePullSecrets | list | `[]` | Existing Image pull secrets for image verify and imageData policies. This will define the `--imagePullSecrets` Kyverno argument. |
| resources.limits | object | `{"memory":"384Mi"}` | Pod resource limits |
| resources.requests | object | `{"cpu":"100m","memory":"128Mi"}` | Pod resource requests |
| initResources.limits | object | `{"cpu":"100m","memory":"256Mi"}` | Pod resource limits |
| initResources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| testResources.limits | object | `{"cpu":"100m","memory":"256Mi"}` | Pod resource limits |
| testResources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| startupProbe | object | See [values.yaml](values.yaml) | Startup probe. The block is directly forwarded into the deployment, so you can use whatever startupProbes configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| livenessProbe | object | See [values.yaml](values.yaml) | Liveness probe. The block is directly forwarded into the deployment, so you can use whatever livenessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| readinessProbe | object | See [values.yaml](values.yaml) | Readiness Probe. The block is directly forwarded into the deployment, so you can use whatever readinessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| generatecontrollerExtraResources | list | `[]` | Additional resources to be added to controller RBAC permissions. |
| excludeKyvernoNamespace | bool | `true` | Exclude Kyverno namespace Determines if default Kyverno namespace exclusion is enabled for webhooks and resourceFilters |
| resourceFiltersExcludeNamespaces | list | `[]` | resourceFilter namespace exclude Namespaces to exclude from the default resourceFilters |
| config.resourceFilters | list | See [values.yaml](values.yaml) | Resource types to be skipped by the Kyverno policy engine. Make sure to surround each entry in quotes so that it doesn't get parsed as a nested YAML list. These are joined together without spaces, run through `tpl`, and the result is set in the config map. |
| config.existingConfig | string | `""` | Name of an existing config map (ignores default/provided resourceFilters) |
| config.annotations | object | `{}` | Additional annotations to add to the configmap |
| config.excludeGroupRole | string | `nil` | Exclude group role |
| config.excludeUsername | string | `nil` | Exclude username |
| config.webhooks | string | `nil` | Defines the `namespaceSelector` in the webhook configurations. Note that it takes a list of `namespaceSelector` and/or `objectSelector` in the JSON format, and only the first element will be forwarded to the webhook configurations. The Kyverno namespace is excluded if `excludeKyvernoNamespace` is `true` (default) |
| config.generateSuccessEvents | bool | `false` | Generate success events. |
| config.metricsConfig | object | `{"annotations":{},"namespaces":{"exclude":[],"include":[]}}` | Metrics config. |
| config.webhookAnnotations | object | `{}` | Defines annotations to set on webhook configurations. |
| config.metricsConfig.annotations | object | `{}` | Additional annotations to add to the metricsconfigmap |
| updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| service.port | int | `443` | Service port. |
| service.type | string | `"ClusterIP"` | Service type. |
| service.nodePort | string | `nil` | Service node port. Only used if `service.type` is `NodePort`. |
| service.annotations | object | `{}` | Service annotations. |
| topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| metricsService.create | bool | `true` | Create service. |
| metricsService.port | int | `8000` | Service port. Kyverno's metrics server will be exposed at this port. |
| metricsService.type | string | `"ClusterIP"` | Service type. |
| metricsService.nodePort | string | `nil` | Service node port. Only used if `metricsService.type` is `NodePort`. |
| metricsService.annotations | object | `{}` | Service annotations. |
| serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| serviceMonitor.additionalLabels | string | `nil` | Additional labels |
| serviceMonitor.namespace | string | `nil` | Override namespace (default is the same as kyverno) |
| serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| createSelfSignedCert | bool | `false` | Kyverno requires a certificate key pair and corresponding certificate authority to properly register its webhooks. This can be done in one of 3 ways: 1) Use kube-controller-manager to generate a CA-signed certificate (preferred) 2) Provide your own CA and cert.    In this case, you will need to create a certificate with a specific name and data structure.    As long as you follow the naming scheme, it will be automatically picked up.    kyverno-svc.(namespace).svc.kyverno-tls-ca (with data entries named tls.key and tls.crt)    kyverno-svc.kyverno.svc.kyverno-tls-pair (with data entries named tls.key and tls.crt) 3) Let Helm generate a self signed cert, by setting createSelfSignedCert true If letting Kyverno create its own CA or providing your own, make createSelfSignedCert is false |
| installCRDs | bool | `true` | Whether to have Helm install the Kyverno CRDs. If the CRDs are not installed by Helm, they must be added before policies can be created. |
| crds.annotations | object | `{}` | Additional CRDs annotations. |
| networkPolicy.enabled | bool | `false` | When true, use a NetworkPolicy to allow ingress to the webhook This is useful on clusters using Calico and/or native k8s network policies in a default-deny setup. |
| networkPolicy.ingressFrom | list | `[]` | A list of valid from selectors according to https://kubernetes.io/docs/concepts/services-networking/network-policies. |
| webhooksCleanup.enable | bool | `false` | Create a helm pre-delete hook to cleanup webhooks. |
| webhooksCleanup.image | string | `"bitnami/kubectl:latest"` | `kubectl` image to run commands for deleting webhooks. |
| tufRootMountPath | string | `"/.sigstore"` | A writable volume to use for the TUF root initialization. |
| customCAConfigMap | string | | Configmap storing custom CA certificate |
| systemCertPath | string | `/etc/ssl/certs` | Path containing ssl certs within the container. Used only if customCAConfigMap is used |
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
| grafana.enabled | bool | `false` | Enable grafana dashboard creation. |
| grafana.namespace | string | `nil` | Namespace to create the grafana dashboard configmap. If not set, it will be created in the same namespace where the chart is deployed. |
| grafana.annotations | object | `{}` | Grafana dashboard configmap annotations. |
| cleanupController.enabled | bool | `true` | Enable cleanup controller. |
| cleanupController.rbac.create | bool | `true` | Create RBAC resources |
| cleanupController.rbac.serviceAccount.name | string | `nil` | Service account name |
| cleanupController.rbac.clusterRole.extraResources | list | `[]` | Extra resource permissions to add in the cluster role |
| cleanupController.createSelfSignedCert | bool | `false` | Create self-signed certificates at deployment time. The certificates won't be automatically renewed if this is set to `true`. |
| cleanupController.image.registry | string | `nil` | Image registry |
| cleanupController.image.repository | string | `"ghcr.io/kyverno/cleanup-controller"` | Image repository |
| cleanupController.image.tag | string | `nil` | Image tag Defaults to appVersion in Chart.yaml if omitted |
| cleanupController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| cleanupController.image.pullSecrets | list | `[]` | Image pull secrets |
| cleanupController.replicas | int | `nil` | Desired number of pods |
| cleanupController.updateStrategy | object | See [values.yaml](values.yaml) | Deployment update strategy. Ref: https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy |
| cleanupController.priorityClassName | string | `""` | Optional priority class |
| cleanupController.hostNetwork | bool | `false` | Change `hostNetwork` to `true` when you want the pod to share its host's network namespace. Useful for situations like when you end up dealing with a custom CNI over Amazon EKS. Update the `dnsPolicy` accordingly as well to suit the host network mode. |
| cleanupController.dnsPolicy | string | `"ClusterFirst"` | `dnsPolicy` determines the manner in which DNS resolution happens in the cluster. In case of `hostNetwork: true`, usually, the `dnsPolicy` is suitable to be `ClusterFirstWithHostNet`. For further reference: https://kubernetes.io/docs/concepts/services-networking/dns-pod-service/#pod-s-dns-policy. |
| cleanupController.extraArgs | list | `[]` | Extra arguments passed to the container on the command line |
| cleanupController.resources.limits | object | `{"memory":"128Mi"}` | Pod resource limits |
| cleanupController.resources.requests | object | `{"cpu":"100m","memory":"64Mi"}` | Pod resource requests |
| cleanupController.startupProbe | object | See [values.yaml](values.yaml) | Startup probe. The block is directly forwarded into the deployment, so you can use whatever startupProbes configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.livenessProbe | object | See [values.yaml](values.yaml) | Liveness probe. The block is directly forwarded into the deployment, so you can use whatever livenessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.readinessProbe | object | See [values.yaml](values.yaml) | Readiness Probe. The block is directly forwarded into the deployment, so you can use whatever readinessProbe configuration you want. ref: https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-probes/ |
| cleanupController.nodeSelector | object | `{}` | Node labels for pod assignment |
| cleanupController.tolerations | list | `[]` | List of node taints to tolerate |
| cleanupController.antiAffinity.enabled | bool | `true` | Pod antiAffinities toggle. Enabled by default but can be disabled if you want to schedule pods to the same node. |
| cleanupController.podAntiAffinity | object | See [values.yaml](values.yaml) | Pod anti affinity constraints. |
| cleanupController.podAffinity | object | `{}` | Pod affinity constraints. |
| cleanupController.nodeAffinity | object | `{}` | Node affinity constraints. |
| cleanupController.topologySpreadConstraints | list | `[]` | Topology spread constraints. |
| cleanupController.podSecurityContext | object | `{}` | Security context for the pod |
| cleanupController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Security context for the containers |
| cleanupController.podDisruptionBudget.minAvailable | int | `1` | Configures the minimum available pods for disruptions. Cannot be used if `maxUnavailable` is set. |
| cleanupController.podDisruptionBudget.maxUnavailable | string | `nil` | Configures the maximum unavailable pods for disruptions. Cannot be used if `minAvailable` is set. |
| cleanupController.service.port | int | `443` | Service port. |
| cleanupController.service.type | string | `"ClusterIP"` | Service type. |
| cleanupController.service.nodePort | string | `nil` | Service node port. Only used if `service.type` is `NodePort`. |
| cleanupController.service.annotations | object | `{}` | Service annotations. |
| cleanupController.metricsService.create | bool | `true` | Create service. |
| cleanupController.metricsService.port | int | `8000` | Service port. Metrics server will be exposed at this port. |
| cleanupController.metricsService.type | string | `"ClusterIP"` | Service type. |
| cleanupController.metricsService.nodePort | string | `nil` | Service node port. Only used if `metricsService.type` is `NodePort`. |
| cleanupController.metricsService.annotations | object | `{}` | Service annotations. |
| cleanupController.serviceMonitor.enabled | bool | `false` | Create a `ServiceMonitor` to collect Prometheus metrics. |
| cleanupController.serviceMonitor.additionalLabels | string | `nil` | Additional labels |
| cleanupController.serviceMonitor.namespace | string | `nil` | Override namespace (default is the same as kyverno) |
| cleanupController.serviceMonitor.interval | string | `"30s"` | Interval to scrape metrics |
| cleanupController.serviceMonitor.scrapeTimeout | string | `"25s"` | Timeout if metrics can't be retrieved in given time interval |
| cleanupController.serviceMonitor.secure | bool | `false` | Is TLS required for endpoint |
| cleanupController.serviceMonitor.tlsConfig | object | `{}` | TLS Configuration for endpoint |
| cleanupController.tracing.enabled | bool | `false` | Enable tracing |
| cleanupController.tracing.address | string | `nil` | Traces receiver address |
| cleanupController.tracing.port | string | `nil` | Traces receiver port |
| cleanupController.tracing.creds | string | `""` | Traces receiver credentials |
| cleanupController.logging.format | string | `"text"` | Logging format |
| cleanupController.metering.disabled | bool | `false` | Disable metrics export |
| cleanupController.metering.config | string | `"prometheus"` | Otel configuration, can be `prometheus` or `grpc` |
| cleanupController.metering.port | int | `8000` | Prometheus endpoint port |
| cleanupController.metering.collector | string | `""` | Otel collector endpoint |
| cleanupController.metering.creds | string | `""` | Otel collector credentials |

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

If `createSelfSignedCert` is `true`, Helm will take care of the steps of creating an external self-signed certificate described in option 2 of the [installation documentation](https://kyverno.io/docs/installation/#option-2-use-your-own-ca-signed-certificate)

If `createSelfSignedCert` is `false`, Kyverno will generate a self-signed CA and a certificate, or you can provide your own TLS CA and signed-key pair and create the secret yourself as described in the [documentation](https://kyverno.io/docs/installation/#customize-the-installation-of-kyverno).

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

## Kyverno CLI

See: https://kyverno.io/docs/kyverno-cli/

## Requirements

Kubernetes: `>=1.16.0-0`

