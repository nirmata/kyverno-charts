# Helm Chart for Nirmata Kyverno Operator CRD
Nimata Kyverno Operator CRD is a prerequisite chart to install Kyverno Operator inside a cluster.

## Prerequisites

### (Optional) If a custom CA is used, create a configmap corresponding to the same with key custom-ca.pem. E.g.
Create the namespace
```bash
kubectl create namespace nirmata-system
```
Create configmap in the namespace
```bash
kubectl -n nirmata-system create configmap <e.g. ca-store-cm> --from-file=custom-ca.pem=<cert file e.g. some-cert.pem>
```

## Getting Started

***Kyverno v1.10.x has breaking changes. If you are upgrading from v1.9 or earlier versions, please see [Upgrading to Kyverno 1.10.x from earlier Kyverno versions](#upgrading-from-earlier-versions) before proceeding further***

Add the chart repository and install the chart
```bash
helm repo add nirmata https://nirmata.github.io/kyverno-charts
helm repo update nirmata
```

## Installing

Install the CRD first

```bash
helm install nirmata-kyverno-operator-crd nirmata/nirmata-kyverno-operator-crd -n nirmata-system --create-namespace
```

Once CRD is been installed we can install the operator 

```bash
helm install nirmata-kyverno-operator nirmata/nirmata-kyverno-operator -n nirmata-system --create-namespace --set licenseKey=<licenseKey>[,apiKey=<api key>] [--version v0.3.0-rc.. if using release candidate]
```

## Uninstalling

Uninstall the operator first

```bash
helm uninstall nirmata-kyverno-operator -n nirmata-system
```

Once operator is been uninstalled, we can uninstall the CRD from the cluster

```bash
helm uninstall nirmata-kyverno-operator-crd -n nirmata-system
```
