# Kyverno Monitor

[Kyverno](https://kyverno.io) is a Kubernetes Native Policy Management engine. Kyverno monitor monitors Kyverno resources and policies to check for potential tampering. 

## Introduction

This chart bootstraps a Kyverno Monitor on a [Kubernetes](http://kubernetes.io) cluster with [Kyverno](https://kyverno.io) installed, using the [Helm](https://helm.sh) package manager.

## Installation

```
# 1. Add Kyverno Helm Repository

helm repo add nirmata https://nirmata.github.io/kyverno-charts/

# 2. Install kyverno-monitor from nirmata helm repo with desired parameters.

helm install kyverno-monitor nirmata/kyverno-monitor --set namespace=<namespace>

# 3. Check pods are running
kubectl -n <namespace> get pods 

# 4. Check CRD is created
kubectl -n <namespace> get KyvernoMonitor
```

## Uninstalling the Chart

To uninstall/delete the `kyverno-monitor` deployment:

```console
helm -n <namespace> kyverno-monitor
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the kyverno chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| validKyvernoImages | string | `ghcr.io/nirmata/kyverno-monitor:xxx` | Valid images separated by pipe |
