# kube-bench-adapter

![Version: 0.1.1](https://img.shields.io/badge/Version-0.1.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: 1.16.0](https://img.shields.io/badge/AppVersion-1.16.0-informational?style=flat-square)

The kube-bench adapter periodically runs a CIS benchmark check using cron-job with a tool called kube-bench and produces a cluster-wide policy report based on the Policy Report Custom Resource Definition

## Installation

```
# 1. Add Kyverno Helm Repository

helm repo add nirmata https://nirmata.github.io/kyverno-charts/

# 2. Install kube-bench adapter from nirmata helm repo with desired parameters.

helm install kube-bench-adapter nirmata/kube-bench-adapter --set kubeBench.name="test-1" --set kubeBench.yaml="job-eks.yaml" --set kubeBench.benchmark="cis-1.6"

# 3. Watch the jobs
kubectl get jobs --watch

# 4. Check policyreports created through the custom resource
kubectl get clusterpolicyreports
```
## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| cronjob.schedule | string | `"\"*/2 * * * *\""` | cronjob schedule, default is 2 mins. |
| fullnameOverride | string | `""` |  |
| image.pullPolicy | string | `"Always"` |  |
| image.repository | string | `"ghcr.io/nirmata/kube-bench-adapter"` | image repository of kube-bench-adapter |
| image.tag | string | `"latest"` | tag of image repository of kube-bench-adapter |
| imagePullSecrets | list | `[]` |  |
| ingress.annotations | object | `{}` |  |
| ingress.enabled | bool | `false` |  |
| ingress.hosts[0].host | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].backend.serviceName | string | `"chart-example.local"` |  |
| ingress.hosts[0].paths[0].backend.servicePort | int | `80` |  |
| ingress.hosts[0].paths[0].path | string | `"/"` |  |
| ingress.tls | list | `[]` |  |
| kubeBench.benchmark | string | `"cis-1.6"` | specify the benchmark for kube-bench job, allowed values:cis-1.5, cis-1.6, gke-1.0, eks-1.0, ack-1.0 |
| kubeBench.category | string | `"CIS Benchmarks"` | category of the policy report |
| kubeBench.command | string | `"policyreport"` |  |
| kubeBench.kubebenchImg | string | `"aquasec/kube-bench:latest"` | kube-bench image used for the adapter |
| kubeBench.kubeconfig | string | `"$HOME/.kube/config"` | absolute path to the kubeconfig file |
| kubeBench.name | string | `"kube-bench"` | name of kube-bench adapter cluster policy report |
| kubeBench.namespace | string | `"default"` | specifies namespace where kube-bench job will run |
| kubeBench.targets | string | `"master,node,etcd,policies"` | targets for benchmark of kube-bench job, multiple values allowed. |
| kubeBench.version | string | `"1.21"` | specify the Kubernetes version for kube-bench job |
| kubeBench.yaml | string | `"job.yaml"` | name of name of YAML for kube-bench job, allowed values: job.yaml, job-master.yaml, job-node.yaml, job-ack.yaml, job-aks.yaml, job-eks-asff.yaml, job-eks.yaml, job-gke.yaml, job-iks.yaml |
| nameOverride | string | `""` |  |
| rbac.create | bool | `true` |  |
| replicaCount | int | `1` |  |
| service.port | int | `80` |  |
| service.type | string | `"NodePort"` |  |
| serviceAccount.annotations | object | `{}` |  |
| serviceAccount.create | bool | `true` |  |
| serviceAccount.name | string | `""` |  |

