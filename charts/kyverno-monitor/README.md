# Kyverno Monitor

[Kyverno](https://kyverno.io) is a Kubernetes Native Policy Management engine. Kyverno monitor monitors Kyverno resources and policies to check for potential tampering. 

## Introduction

This chart bootstraps a Kyverno Monitor on a [Kubernetes](http://kubernetes.io) cluster with [Kyverno](https://kyverno.io) installed, using the [Helm](https://helm.sh) package manager.

## Installation

```
# 1. Add Kyverno Helm Repository

helm repo add nirmata https://nirmata.github.io/kyverno-charts/

# 2. Install kyverno-monitor from nirmata helm repo in the nirmata-kyverno-monitor namespace, with desired parameters.

helm install kyverno-monitor nirmata/kyverno-monitor --namespace nirmata-kyverno-monitor --create-namespace --set imagePullSecret.username=someuser,imagePullSecret.password=somepassword


# 3. Check pods are running
kubectl -n <namespace> get pods 

# 4. Check CRD is created
kubectl -n <namespace> get KyvernoMonitor
```

## Testing the chart
```
# 1. Check that the isRunning status of the KyvernoMonitor CRD is true
kubectl -n <namespace> get KyvernoMonitor -o yaml

# 2. Change the kyverno deployment, say by reducing replicas to 0
kubectl -n kyverno scale deploy kyverno --replicas=0

# 3. Check the KyvernoMonitor CRD again, and see that the isRunning flag is set to false. Also check that the LastModified field for Deployment shows current time.

# 4. Revert the kyverno replicas to previous number and check that the isRunning and LastModified fields are changed.
```
## Uninstalling the Chart

To uninstall/delete the `kyverno-monitor` deployment:

```console
helm delete -n<namespace> kyverno-monitor
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the kyverno chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| namespace | string | `nirmata-kyverno-monitor` | Namespace to install kyverno-monitor resources |
| imagePullSecret.name | string | `image-pull-secret` | Imagepull secret name that will store private image registry info |
| imagePullSecret.create | boolean | `true` | Whether to create the image pullsecret. Need to specify the secret name, username, password |
| imagePullSecret.username | string |  | Private registry username if secret is to be created |
| imagePullSecret.password | string |  | Private registry password if secret is to be created |
| validKyvernoImages | string | `ghcr.io/nirmata/kyverno:xxx` | Valid images separated by pipe symbol, xxx for any version |
| kyvernoMonitorImage | string | `ghcr.io/nirmata/kyverno-monitor` | Kyverno monitor image |
| kyvernoMonitorImageTag | string | `0.1.0` | Kyverno monitor image tag. If empty, appVersion in Chart.yaml is used |
