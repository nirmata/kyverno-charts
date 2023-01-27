# Kyverno Operator

[Kyverno](https://kyverno.io) is a Kubernetes Native Policy Management engine. Kyverno operator monitors Kyverno resources and policies to check for potential tampering. 

## Introduction

This chart bootstraps a Kyverno Operator on a [Kubernetes](http://kubernetes.io) cluster with [Kyverno](https://kyverno.io) installed, using the [Helm](https://helm.sh) package manager.

## Prerequisite
### Get token from Nirmata support
You need token to download the images. Please contact <support@nirmata.com> to get it.

## Installation

### 1. Add Kyverno Helm Repository
```console
helm repo add nirmata https://nirmata.github.io/kyverno-charts/
helm repo update nirmata
```

### 2. (Optional) If a custom CA is used, create a configmap corresponding to the same with key custom-ca.pem. E.g.
Create the namespace
```console
kubectl create namespace nirmata-kyverno-operator
```
Create configmap in the namespace
```console
kubectl -n nirmata-kyverno-operator create configmap <e.g. ca-store-cm> --from-file=custom-ca.pem=<cert file e.g. some-cert.pem>
```

### 3. Install kyverno-operator from nirmata helm repo in the nirmata-kyverno-operator namespace, with desired parameters.
```console
helm install kyverno-operator nirmata/kyverno-operator --namespace nirmata-kyverno-operator --create-namespace
```

Other parameters corresponding to custom CA or HTTP proxies, NO_PROXY should be provided as needed. E.g.
```console
--set customCAConfigMap=<e.g. ca-store-cm> --set systemCertPath=<e.g. /etc/ssl/certs>  --set "extraEnvVars[0].name=HTTP_PROXY" --set "extraEnvVars[0].value=<e.g. http://test.com:8080>" ...
```

### 4. Check pods are running
```console
kubectl -n nirmata-kyverno-operator get pods
```

### 5. Check CRD is created
```console
kubectl -n nirmata-kyverno-operator get KyvernoOperator
```

## Testing the chart

### 1. Check that the isRunning status of the KyvernoOperator CRD is true
```console
kubectl -n nirmata-kyverno-operator get KyvernoOperator -o yaml | grep -e isRunning
```

### 2. Change the kyverno deployment, say by reducing replicas to 0
```console
kubectl -n kyverno scale deploy kyverno --replicas=0
```

### 3. Check the KyvernoOperator CRD again, and see that the isRunning flag is set to false. Also check that the LastModified field for Deployment shows current time.
```console
kubectl -n nirmata-kyverno-operator get KyvernoOperator -o yaml | grep -e isRunning
```

### 4. Revert the kyverno replicas to previous number and check that the isRunning and lastModifiedAt fields are changed.
```console
kubectl -n kyverno scale deploy kyverno --replicas=1
kubectl -n nirmata-kyverno-operator get KyvernoOperator -o yaml | grep -e isRunning -e lastModifiedAt
```

## Uninstalling the Chart

To uninstall/delete the `kyverno-operator` deployment:
```console
helm delete -n nirmata-kyverno-operator kyverno-operator
```

The command removes all the Kubernetes components associated with the chart and deletes the release.

Note: The crd `kyvernooperator.security.nirmata.io` needs to be deleted manually


## Configuration

The following table lists the configurable parameters of the kyverno chart and their default values.

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| namespace | string | `nirmata-kyverno-operator` | Namespace to install kyverno-operator resources |
| imagePullSecret.name | string | `image-pull-secret` | Imagepull secret name that will store private image registry info |
| imagePullSecret.create | boolean | `false` | Whether to create the image pullsecret. Need to specify the secret name, username, password |
| imagePullSecret.username | string |  | Private registry username if secret is to be created |
| imagePullSecret.password | string |  | Private registry password if secret is to be created |
| validKyvernoImages | string | `ghcr.io/nirmata/kyverno:xxx` | Valid images separated by pipe symbol, xxx for any version |
| kyvernoOperatorImage | string | `ghcr.io/nirmata/kyverno-monitor` | Kyverno operator image |
| kyvernoOperatorImageTag | string | `0.1.0` | Kyverno operator image tag. If empty, appVersion in Chart.yaml is used |
| extraEnvVars | list | `[]` | Array of extra environment variables to pod as key: xxx, value: xxx pairs |
| customCAConfigMap | string | | Configmap storing custom CA certificate |
| systemCertPath | string | `/etc/ssl/certs` | Path containing ssl certs within the container. Used only if customCAConfigMap is used |
