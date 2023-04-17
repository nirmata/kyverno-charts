# image-scan-adapter

A Helm chart for Kubernetes

![Version: v0.1.0](https://img.shields.io/badge/Version-v0.1.0-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: v0.1.0](https://img.shields.io/badge/AppVersion-v0.1.0-informational?style=flat-square)

## Description

The Image Scan Adapter is a Kubernetes controller that integrates with image scanning tools like [Grype](https://github.com/anchore/grype) to generate image scan reports. By leveraging this adapter, users can gain greater visibility into their container images and proactively mitigate any potential security risks. The adapter can be further extended to support other image scanning tools and formats in the future.

## Installation

1. Add the Image Scan Adapter Helm repository:

```console
helm repo add kyverno-charts https://nirmata.github.io/kyverno-charts/
helm repo update kyverno-charts
```

2. Install the Helm Chart:

```console
helm install image-scan-adapter kyverno-charts/image-scan-adapter --namespace image-scan-adapter --create-namespace
```

3. Verify the Image Scan Adapter installation:

```console
kubectl get pods -n image-scan-adapter
```

Wait for the image-scan-adapter pod to be in a Running state before continuing.

4. Check the `status` field of the `isacfg` custom resource created in the installation namespace:

```console
kubectl get isacfg -n image-scan-adapter -o yaml
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `nil` | Override the name of the chart |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| severity | list | `[]` | Severities to include in the generated scan result |
| policyReportPrefix | string | `"image-scan"` | The prefix for policy report file name |
| scannerEngine | string | `"grype"` | Scanner engine to use, "grype" by default |
| outputFormat | string | `"PolicyReport"` | Output format of scan result, "PolicyReport" by default |
| scanInterval | string | `"12h"` | Interval after which scan will run automatically |
| scanAll | bool | `false` | Disable selective scan, "false" by default |
| selectors.namespaces | list | `[]` | Namespaces to run image scan on, by default adapter will scan all namespaces |
| rbac.create | bool | `true` | Enable RBAC resources creation |
| rbac.serviceAccount.name | string | `nil` | Service account name, you MUST provide one when `rbac.create` is set to `false` |
| image.repository | string | `"ghcr.io/nirmata/image-scan-adapter"` | Image repository |
| image.pullPolicy | string | `"Always"` | Image pull policy |
| image.tag | string | `nil` | Image tag (defaults to chart app version) |
| image.imagePullSecrets | list | `[]` | Image pull secrets |

## Maintainers

| Name | Email | Url |
| ---- | ------ | --- |
| Nirmata |  | <https://nirmata.com/> |

