# cluster-registrator

Helm chart for Nirmata Cluster Registrator

![Version: v0.1.3](https://img.shields.io/badge/Version-v0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

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
helm repo update cluster-registrator
```

2. Install the Helm Chart:

```console
helm install cluster-registrator cluster-registrator/cluster-registrator --set cluster.name=<cluster-name> --set apiToken=<api-token>
```

3. Verify the Cluster Registrator installation:

```console
kubectl logs job/nirmata-cluster-registrator -n nirmata -f
```


## Values

| Key | Type | Default | Required | Description |
|-----|------|---------|----------|-------------|
| nirmataURL | string | `"https://nirmata.io"` | No| Nirmata URL|
| cluster.name | string | `nil` | Yes | Name of the cluster in NPM|
| cluster.type | string | `default-policy-manager-type` |No| Type of cluster to be created in NPM |
| apiToken | string | `""` | No |Token required to authenticate into NPM. Need one of apiToken or apiTokenSecret |
| apiTokenSecret | string | `""` | No |Token secret required to authenticate into NPM in key apiKey. Need one of apiToken or apiTokenSecret|
| proxy.httpProxy | string | `""` |No| HTTP_PROXY required for connecting to clusters with Proxy |
| proxy.httpsProxy | string | `""` |No|HTTPS_PROXY required for connecting to clusters with Proxy |
| proxy.noProxy | string | `""` | No|NO_PROXY required for connecting to clusters with Proxy |
| tlsCert | string | `""` | No|TLS CERT to use for tunnel service connection |
| controllerPerms | string | `read-write` | No| Whether registrator should install kube-controller with `read-write` or `read-only` permissions (for NPM) and `read-write-ndp` permissions (for NDP). Used as an additional gate to avoid providing privileges unintentionally. |
| cluster.endpoint | string | `""` |No| For NDP tenants, this is the cluster endpoint for the cluster. Chart version should be 0.1.16 or higher. |


## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Nirmata |  | <https://nirmata.com/> |

