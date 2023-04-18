# cluster-registrator

A Helm chart for Kubernetes

![Version: v0.1.0](https://img.shields.io/badge/Version-v0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

## Description

The Cluster registrator runs a job inside the cluster to register the cluster to NPM. 
Cluster Registrator performs the following steps:
1. Fetches ClusterType resources from Nirmata. It defaults to `default-policy-manager-type`.
2. Created a Cluster resource using the `type` and `name` with 0 nodes.
3. Fetches the YAML manifests to register the cluster.
4. Applies the YAML manifests to create resources and register the cluster.

## Installation

1. Add the Cluster Registrator Helm repository:

```console
helm repo add cluster-registrator https://nirmata.github.io/kyverno-charts/
helm repo update kyverno-charts
```

2. Install the Helm Chart:

```console
helm install cluster-registrator kyverno-charts/cluster-registrator --cluster.name <cluster-name> --apiToken <api-token>
```

3. Verify the Cluster Registrator installation:

```console
kubectl logs job/nirmata-cluster-registrator -n nirmata -f
```


## Values

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| NirmataURL | string | `"https://nirmata.io"` | No| Nirmata URL|
| cluster.name | string | `nil` | Yes | Name of the cluster in NPM|
| cluster.type | string | `default-policy-manager-type` |No| Type of cluster to be created in NPM |
| apiToken | string | `""` | Yes |Token required to authenticate into NPM|
| proxy.httpProxy | string | `""` |No| HTTP_PROXY required for connecting to clusters with Proxy |
| proxy.httpsProxy | string | `""` |No|HTTPS_PROXY required for connecting to clusters with Proxy |
| proxy.noProxy | string | `""` | No|NO_PROXY required for connecting to clusters with Proxy |
| tlsCert | string | `""` | No|TLS CERT to use for tunnel service connection |


## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Nirmata |  | <https://nirmata.com/> |

