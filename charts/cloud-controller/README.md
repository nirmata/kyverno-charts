# cloud-control

![Version: v0.0.1](https://img.shields.io/badge/Version-v0.0.1-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square) ![AppVersion: latest](https://img.shields.io/badge/AppVersion-latest-informational?style=flat-square)

A Helm chart for Kubernetes

By default, the required Custom Resource Definitions (CRDs) for report generation—ephemeralClusterPolicyReport and ClusterPolicyReport—are automatically installed. Additionally, curated policies for ECS, EKS, and Lambda are included in the deployment.

## Configuring primaryAWSAccountConfig
If you want to enable the deployment of the primaryAWSAccountConfig resource by default, you must provide the necessary configuration values in the values.yaml file. Below is the required structure:

```
primaryAWSAccountConfig:
  accountID: ""
  accountName: "" 
  regions: []
  scanInterval: 1h
  services: []
```

### Required Fields

Ensure the following fields are populated for the deployment to proceed


**accountID**: The AWS Account ID (must be a string, e.g., `"123456789012"`).

**accountName**: A meaningful name for the AWS account.  

**regions**: A list of AWS regions to include in the configuration (e.g., `["us-east-1", "us-west-2"]`).

**services**: A list of AWS services to monitor (e.g., `["ECS", "EKS", "Lambda"]`).


### Example Configuration

```
primaryAWSAccountConfig:
  accountID: "844333597536"
  accountName: "devtest"
  regions:
    - us-east-1
    - us-west-2
  scanInterval: 1h
  services:
    - EKS
    - ECS
    - EC2
    - Lambda
```

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| admissionController.args | list | `["--metrics-bind-address=:8080","--leader-elect","--health-probe-bind-address=:8081"]` | Container arguments |
| admissionController.image.pullPolicy | string | `"IfNotPresent"` | Image pull policy |
| admissionController.image.registry | string | `"reg.nirmata.io"` | Image registry |
| admissionController.image.repository | string | `"nirmata/cloud-admission-controller"` | Image repository |
| admissionController.image.tag | string | `"latest"` | Image tag |
| admissionController.imagePullSecrets | object | `{}` | Image pull secrets |
| admissionController.metricsService.createServiceMonitor | bool | `false` | Create service. |
| admissionController.metricsService.ports | list | `[{"name":"http","port":8080,"protocol":"TCP","targetPort":8080}]` | Service ports |
| admissionController.metricsService.type | string | `"ClusterIP"` | Service type |
| admissionController.replicas | int | `nil` | Desired number of pods |
| admissionController.resources.limits | object | `{"cpu":"500m","memory":"128Mi"}` | Pod resource limits |
| admissionController.resources.requests | object | `{"cpu":"10m","memory":"64Mi"}` | Pod resource requests |
| admissionController.securityContext | object | `{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]},"privileged":false,"readOnlyRootFilesystem":true,"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}}` | Container security context |
| admissionController.service.ports | list | `[{"name":"http","port":8443,"protocol":"TCP","targetPort":"http-proxy-svc"}]` | Service ports |
| admissionController.service.type | string | `"ClusterIP"` | Service type |
| admissionController.serviceAccount.annotations | object | `{}` | Annotations for the ServiceAccount |
| admissionController.serviceAccount.name | string | `nil` | The ServiceAccount name |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| kubernetesClusterDomain | string | `"cluster.local"` |  |
| nameOverride | string | `nil` | Override the name of the chart |
| namespaceOverride | string | `nil` | Override the namespace the chart deploys to |

