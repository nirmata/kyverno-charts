# Helm Chart for Enterprise Kyverno
Enterprise Kyverno is a Kubernetes Operator to manage lifecycle of Kyverno, Adapters and Nirmata supported policies. 

## Prerequisites
### Get license key
You need a license key to run Enterprise Kyverno. If you are using Nirmata Enterprise for Kyverno, it is available in the UI. Else contact support@nirmata.com.

### Install cert-manager 
Follow instructions [here](https://cert-manager.io/docs/installation/). Typically,
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
```

## Getting Started
Add the chart repository and install the chart

NOTE: Currently the helm chart is private. Chart can be installed through the repo only after it is released publicly. Till then, clone the github repo and use `./charts/enterprise-kyverno` instead of using the helm repo as below.
```bash
helm repo add nirmata https://nirmata.github.io/kyverno-charts
helm repo update nirmata

helm install kyverno-operator nirmata/enterprise-kyverno-operator -n kyverno-operator --create-namespace --set licenseKey=<licenseKey>
```

View various Resources created
```bash
kubectl -n kyverno-operator get kyvernoes.security.nirmata.io 
kubectl -n kyverno-operator get policysets.security.nirmata.io 

kubectl -n kyverno get po (should show Kyverno pods getting ready)
kubectl get cpol (should show policies installed by initial policysets)
```

Modify config by changing CRs directly or via Helm Upgrade
```bash
kubectl -n kyverno-operator edit kyvernoes.security.nirmata.io kyverno (and set replicas to 3)

helm upgrade kyverno-operator nirmata/enterprise-kyverno-operator -n kyverno-operator --create-namespace --set licenseKey=<licenseKey> --set kyverno.replicas=3
```

Remove a Policy Set 
```bash
kubectl -n kyverno-operator delete policysets best-practices
```

To remove Enterprise Kyverno and components
```bash
helm uninstall -n kyverno-operator kyverno-operator
```

## Helm Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `nil` | Override the name of the chart |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| enableWebhook | bool | `true` | Enable operator webhooks for enhanced error checks and user info in audit log |
| rbac.create | bool | `true` | Enable RBAC resources creation |
| rbac.operatorHasAdminPerms | bool | `false` | Whether operator has admin permissions to install CRD and RBAC |
| rbac.serviceAccount.name | string | `nil` | Service account name when `rbac.create` is set to `false` |
| image.repository | string | `"ghcr.io/nirmata/enterprise-kyverno-operator"` | Image repository |
| image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| image.tag | string | `nil` | Image tag (defaults to chart app version) |
| image.imagePullSecrets.registry | string | `ghcr.io` | Image pull secret registry |
| image.imagePullSecrets.name | string | `image-pull-secret` | Image pull secret name |
| image.imagePullSecrets.create | bool | `false` | Whether to create image pull secret |
| image.imagePullSecrets.username | string | `nil` | Username for image pull secret registry |
| image.imagePullSecrets.password | string | `nil` | Password for image pull secret registry |
| kyverno.majorVersion | string | `1.8` | Kyverno major version |
| kyverno.createCR | bool | `true` | Create a CR that describes Kyverno to be managed by operator |
| kyverno.replicaCount | int | `1` | Kyverno replicas |
| kyverno.rbac.create | bool | `true` | Enable Kyverno RBAC resources creation |
| kyverno.rbac.serviceAccount.create | string | `nil` | Whether to create Kyverno service account |
| kyverno.rbac.serviceAccount.clusterRole.extraResources | list | `[]` | Extra resource permissions to add to the Kyverno cluster role |
| kyverno.generatecontrollerExtraResources | list | `[]]` | Additional resources to be added to kyverno controller RBAC permissions |
| kyverno.image.repository | string | `"ghcr.io/nirmata/kyverno"` | Kyverno Image repository |
| kyverno.image.pullPolicy | string | `"IfNotPresent"` | Kyverno Image pull policy |
| kyverno.image.tag | string | `v1.8.5-n4k-build.1` | Image tag (defaults to chart app version) |
| kyverno.helm | object | `helm.rbac.serviceAccount.name=kyverno` | Free form yaml section with helm parameters in Kyverno chart |
| kyverno.policies.policySets | list | `[{name: best-practices, type: helm, chartRepo: https://nirmata.github.io/kyverno-charts, chartName: best-practice-policies, version: 0.1.0}, {name: pod-security, type: helm, chartRepo: https://nirmata.github.io/kyverno-charts, chartName: pod-security-policies, version: 0.1.0}]` | Initial policy sets to install along with operator |
