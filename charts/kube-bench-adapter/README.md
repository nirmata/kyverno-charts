# kube-bench-adapter

![Version: v1.2.6](https://img.shields.io/badge/Version-v1.2.6-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.2.3](https://img.shields.io/badge/AppVersion-v0.2.3-informational?style=flat-square)

The kube-bench adapter periodically runs a CIS benchmark check using cron-job with a tool called kube-bench and produces a cluster-wide policy report based on the Policy Report Custom Resource Definition.

## Installation

```
# 1. Add Kyverno Helm Repository

helm repo add nirmata https://nirmata.github.io/kyverno-charts/

# 2. Install kube-bench adapter from nirmata helm repo with desired parameters.

helm install kube-bench-adapter nirmata/kube-bench-adapter --set kubeBench.name="cis-k8s-benchmark" --set kubeBench.kubeBenchBenchmark="cis-1.7"

# 3. Watch the jobs
kubectl get jobs --watch

# 4. Check policyreports created through the custom resource
kubectl get clusterpolicyreports
```
## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cronjob.schedule | string | `"@weekly"` | cronjob schedule, default is weekly. |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"ghcr.io/nirmata/kube-bench-adapter"` | image repository of kube-bench-adapter |
| image.tag | string | `"v0.2.3"` | tag of image repository of kube-bench-adapter |
| imagePullSecrets | list | `[]` |  |
| clusterType | string | `""` | use embedded yamls corresponding to cluster type instead of default kube-bench job yaml. E.g. eks, gke, aks |
| customKubeBenchJob | object | `{}` | custom job yaml to override the default kube-bench yaml or cluster specific one specified using clusterType |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].backend.serviceName | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].backend.servicePort | int | `80` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.tls | list | `[]` |  |
| kubeBench.command | string | `"policyreport"` |  |
| kubeBench.timeout | string | `"10m"` | timeout for kube-bench child job to complete |
| kubeBench.nodeSelectorKey | string | `""` | nodeSelector key to run kube-bench job on node with given label key-value |
| kubeBench.nodeSelectorValue | string | `""` | nodeSelector value to run kube-bench job on node with given label key-value |
| kubeBench.kubeBenchImg | string | `"aquasec/kube-bench:v0.6.6"` | kube-bench image used for the adapter |
| kubeBench.kubeconfig | string | `"$HOME/.kube/config"` | absolute path to the kubeconfig file |
| kubeBench.name | string | `"kube-bench"` | name of kube-bench adapter cluster policy report |
| kubeBench.namespace | string | `"default"` | specifies namespace where kube-bench job will run |
| kubeBench.kubeBenchBenchmark | string | `"cis-1.7"` | specify the benchmark for the kube-bench job (see [CIS Kubernetes Benchmark support](https://github.com/aquasecurity/kube-bench/blob/main/docs/platforms.md#cis-kubernetes-benchmark-support)) |
| nameOverride | string | `""` |  |
| rbac.create | bool | `true` |  |
| replicaCount | int | `1` |  |
| service.port | int | `80` |  |
| service.type | string | `"NodePort"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |
