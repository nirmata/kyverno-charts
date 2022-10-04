# Kyverno Monitor

[Kyverno](https://kyverno.io) is a Kubernetes Native Policy Management engine. Kyverno monitor monitors Kyverno resources and policies to check for potential tampering. 

## Introduction

This chart bootstraps a Kyverno Monitor on a [Kubernetes](http://kubernetes.io) cluster with [Kyverno](https://kyverno.io) installed, using the [Helm](https://helm.sh) package manager.

## Installing the Chart

**Add the Kyverno Helm repository:**

```console
$ helm repo add nirmata https://nirmata.github.io/kyverno-charts/
```

**Note:** If you have open source Kyverno installed, please follow the instructions below to upgrade to the Nirmata Enterprise Subscription.

**Create a namespace:**

**Note:** You can skip this step if you have already created the kyverno namespace.

```console
$ kubectl create namespace kyverno
```

**Install the Kyverno chart:**

Install the Kyverno Chart using documentation [here](https://github.com/nirmata/kyverno-charts/blob/main/charts/nirmata/README.md)

## Uninstalling the Chart

To uninstall/delete the `kyverno` deployment:

```console
helm delete -n kyverno kyverno
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the kyverno chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| namespace | string | `nirmata` | Namespace to install kyverno-monitor resources |

Specify each parameter using the `--set key=value[,key=value]` argument to `helm install`. For example,

```console
$ helm install --namespace nirmata kyverno-monitor ./charts/kyverno-monitor \
  --set=namespace=kyverno-monitor
```

Alternatively, a YAML file that specifies the values for the above parameters can be provided while installing the chart. For example,

```console
$ helm install --namespace nirmata kyverno-monitor ./charts/kyverno-monitor -f values.yaml
```

