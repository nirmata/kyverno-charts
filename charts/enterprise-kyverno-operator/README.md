# Helm Chart for Nirmata Kyverno Operator
Nirmata Kyverno Opertor is a Kubernetes Operator to manage lifecycle of Kyverno, Adapters and Nirmata supported policies. 

## Prerequisites

As a prerequisite, user needs to install [kyverno-operator-crd](../enterprise-kyverno-operator-crd/) to install operator.

### Get license key
You need a license key to run Enterprise Kyverno. If you are using `Enterprise for Kyverno`, or `Nirmata Policy Manager`, it is available in the UI. Else contact `support@nirmata.com`.

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

helm install nirmata-kyverno-operator nirmata/nirmata-kyverno-operator -n nirmata-system --create-namespace --set licenseKey=<licenseKey>[,apiKey=<api key>] [--version v0.3.0-rc.. if using release candidate]
```
Helm Chart parameters for further fine-tuning the above helm install are described in the [Helm Chart Values](#helm-chart-values) section below.

Additional parameters corresponding to custom CA or HTTP proxies, NO_PROXY should be provided as needed. E.g.
```bash
--set customCAConfigMap=<e.g. ca-store-cm> --set systemCertPath=<e.g. /etc/ssl/certs>  --set "extraEnvVars[0].name=HTTP_PROXY" --set "extraEnvVars[0].value=<e.g. http://test.com:8080>" ...
```

View various Resources created
```bash
kubectl -n nirmata-system get kyvernoconfigs.security.nirmata.io #(CR that defines kyverno settings)
kubectl -n nirmata-system get policysets.security.nirmata.io #(CRs corresponding to default policysets installed)

kubectl -n kyverno get po #(should show Kyverno pods getting ready)
kubectl get cpol #(should show policies installed by initial policysets)
```

If you need to modify Kyverno configuration, change CR directly or via Helm Upgrade. (Note: If upgrading from earlier versions to 1.10.x, please read [Upgrading to Kyverno 1.10.x from earlier Kyverno versions](#upgrading-from-earlier-versions) first)

```bash
kubectl -n nirmata-system edit kyvernoconfigs.security.nirmata.io kyverno (and set replicas to 3)

helm upgrade nirmata-kyverno-operator nirmata/nirmata-kyverno-operator -n nirmata-system --create-namespace --set licenseKey=<licenseKey> --set kyverno.replicas=3
```

Removing a Policy Set CR removes policies contained in it
```bash
kubectl -n nirmata-system delete policysets best-practices
```

To remove Nirmata Kyverno Operator and components
```bash
helm uninstall -n nirmata-system nirmata-kyverno-operator
```

## Upgrading from earlier versions
There are many breaking changes in Kyverno 1.10. So we recommend doing a clean installation. Please refer to the [Kyverno 1.10 release notes](https://github.com/kyverno/kyverno/releases/tag/v1.10.0) to understand these breaking changes. Follow the below steps to, take a backup of key resources in Kyverno v1.9 or earlier, do a clean install of Kverno 1.10.x, and restore backed up Kyverno policies after migrating them over to v1.10.

NOTE: In the kubectl commands below, replace namespace `nirmata-system` with appropriate namespace used your setup.

### Take backups
1. Save custom values with which you had installed kyverno operator. E.g.
```bash
helm get values -n nirmata-system kyverno-operator > oldValues.yaml
```
You might need to remove a couple of helm output messages from the old values yaml file saved above. These values will be leveraged later when we install 1.10. 

2. Take a backup of existing policies. This is more important if you have installed policies in addition to the Nirmata policies installed by default. E.g.
`kubectl get cpol pol1 pol2 pol3 ... -o yaml > mypolBkp.yaml` or `kubectl get cpol -o yaml > allPolBkp.yaml`

3. Take a backup of existing Kyvernoes and PolicySet CRs. It is needed if these CRs have been changed manually outside of the helm install/upgrade commands. E.g.
`kubectl -n nirmata-system get kyvernoes kyverno -o yaml > kyvernoCRBkp.yaml` and `kubectl -n nirmata-system get policysets -o yaml > policySetCRBkp.yaml`

4. Take a backup of policy reports for reference. They will be regenerated anyways. E.g. 
`kubectl get polr -A -o yaml > bkpPolr.yaml`

### Uninstall existing version
1. Uninstall operator (which will uninstall kyverno and policies) as described at the end of the [Getting Started](#getting-started) section.
2. Uninstall Kyverno CRDs installed by earlier operator
```bash
kubectl delete crd clusterpolicyreports.wgpolicyk8s.io policyreports.wgpolicyk8s.io
```

### Modify 'kyverno.helm' section in operator values yaml
In case there was any customization done to the `kyverno.helm` section of Kyverno Operator values.yaml file, some values might need to migrated as per the `New Chart Values` section of the [Kyverno 1.10 migration guide](https://github.com/kyverno/kyverno/blob/release-1.10/charts/kyverno/README.md#migrating-from-v2-to-v3). This is because the chart values for the Kyverno 1.10 helm chart have changed significantly.


### Install Kyverno 1.10 using the Operator

Pull the latest nirmata charts repo and install kyverno operator 1.10. Also verify installation. This part is same as the standard clean install described in the [Getting Started](#getting-started) section. The old values.yaml file saved earlier, modified if needed, should also be provided. E.g.
```bash
helm install kyverno-operator nirmata/enterprise-kyverno-operator -n nirmata-system --create-namespace [--version v0.3.2-rc1 or equivalent version if using RC] --set licenseManger.licenseKey=xxxx --set licenseManager.apiKey=xxxx> -f oldValuesWithHelmModified.yaml
```

### Modify 'spec' sections in kyverno CR if changed manually
In case there was any direct change done to the kyvernoes CR outside helm, then those changes needed to applied manually again using `kubectl edit` or equivalent. Mainly, changes to the `spec.helm.values` section of Kyvernoes CR. Within these also, some parameters might need to migrated as per the `New Chart Values` section of the [Kyverno 1.10 migration guide](https://github.com/kyverno/kyverno/blob/release-1.10/charts/kyverno/README.md#migrating-from-v2-to-v3).

### Create/Delete Modify PolicySet CRs if changed manually
Similar to the `spec` section of the kyverno CR described above, if manual addition/deletion or changes to PolicySet CRs had been done outside of helm commands, those need to be applied again using values in the PolicySet backup yamls. For instance, parameters such as helm chart repo or username/passwords, policy validationfailureaction settings saved in the policyset backups need to be reapplied in the new policyset resource definitions.

### Reinstall migrated custom policies
Modify the other custom policies created (backed up earlier) if needed, such that they follow the guidelines described in [breaking changes in Kyverno 1.10](https://github.com/kyverno/kyverno/releases/tag/v1.10.0), in case of breaking changes.

Apply them to the cluster. E.g.
```bash
kubectl apply -f mypolBkpUpgraded.yaml
```
Verify that those policies/policysets show up as ready and are working as expected. The 1.10 compatible versions of Nirmata supplied policysets are already as per those guidelines, so there is no need to change them. 

## Configure Adapters
Adapters such as AWS, CIS, Image Scan and others can be configured by setting appropriate flags corresponding to that adapter. In general, we need to provide 2 flags
- Flags to create RBAC resources such as clusterroles, bindings, serviceaccounts. E.g. for CIS Adapter provide `--set cisAdapter.rbac.create=true --set cisAdapter.serviceAccount.create=true`.
- Flags to create the CR for that adapter at chart install time itself. E.g. for CIS Adapter `--set cisAdapter.createCR=true`
- Similarly for other adapters, like `awsAdapter.`... and `imageScanAdapter.`...

See the Helm chart values below for specifics on each adapter.

## Profiles
The chart allows specification of a `profile` which is like a shorthand for recommended settings while installing operator in various deployment and other environments. These are:
- `nil`: Defaults to prod mode. Policy tamper detection on, non-HA mode for Kyverno, policysets for pod security.
- `dev`: Policy tamper detection off, non-HA mode for Kyverno, policysets for pod security, and rbac best practices.
- `prod`: Policy tamper detection on, HA mode for Kyverno with 3 replicas, policysets for pod security, and rbac best practices.

In case any argument determining the above profiles are explicitly provided, those will override the values inferred from profiles.

## Cloud Platform (values.cloudPlatform)
There are platform specific configurations in which the Kyverno Helm chart configuration varies. Refer to the complete [platform notes](https://kyverno.io/docs/installation/platform-notes) here. Default value is "". Cloud Platforms:
- `aks`
- `eks`
- `openshift`

## Troubleshooting

### Webhook server cert error when installing via ArgoCD
While installing the operator Helm Chart via ArgoCD, we might see a webhook error like this:

```
Error from server (InternalError): Internal error occurred: failed calling webhook "mutate.kyverno.svc-fail": Post "https://infra-kyverno-svc.infra.svc:443/mutate?timeout=10s": x509: certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "*.kyverno.svc")
```
The CA certificate in the operator secret `nirmata-system/webhook-server-cert` and that in the validating webhookconfiguration `kyverno-operator-validating-webhook-configuration` should match. Operator rewrites the webhookconfiguration and the secret too, after install. So, ArgoCD will show it as a drift. To fix it, we can use the following to the ArgoCD app manifest:

```
spec:
  ignoreDifferences:
  - name: webhook-server-secret
    kind: Secret
    jsonPointers:
    - /data/tls.key
    - /data/tls.crt
    - /data/ca.crt
```

### Error creating Kyverno CR when installing via ArgoCD
The Kyverno CR creation might fail when sync'ing the ArgoCD app. This could happen because ArgoCD has problems installing Helm Charts having both a CRD as well as CR. For that, we need to add a retry so that the CR can be applied after the CRD is ready. E.g.

```
syncPolicy:
  syncOptions:
    - CreateNamespace=true
    - ApplyOutOfSyncOnly=true
    - ServerSideApply=true
  retry:
    limit: 2
    backoff:
      duration: 20s
      factor: 2
      maxDuration: 3m0s
```

## Helm Chart Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| nameOverride | string | `nil` | Override the name of the chart |
| fullnameOverride | string | `nil` | Override the expanded name of the chart |
| enableWebhook | bool | `true` | Enable operator webhooks for enhanced error checks and user info in audit log |
| certManager | string | `operator` | Webhook cert management mechanism. Valid values are "operator", "cert-manager", "other". |
| licenseKey | string | `nil`| License key (required) |
| apiKey | string | `nil` | License server API key |
| profile | string | `prod` | Operator profile, one of `dev`, `prod`, `nil`. See description of profiles above.  |
| customCAConfigMap | string | | Configmap storing custom CA certificate |
| systemCertPath | string | `/etc/ssl/certs` | Path containing ssl certs within the container. Used only if customCAConfigMap is used |
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
| kyverno.createCR | bool | `true` | Create a CR that describes Kyverno to be managed by operator |
| kyverno.replicaCount | int | `1` | Kyverno replicas |
| kyverno.rbac.create | bool | `true` | Enable Kyverno RBAC resources creation |
| kyverno.rbac.serviceAccount.create | string | `nil` | Whether to create Kyverno service account |
| kyverno.rbac.serviceAccount.clusterRole.extraResources | list | `[]` | Extra resource permissions to add to the Kyverno cluster role |
| kyverno.generatecontrollerExtraResources | list | `[]` | Additional resources to be added to kyverno controller RBAC permissions |
| kyverno.image.repository | string | `"ghcr.io/nirmata/kyverno"` | Kyverno Image repository |
| kyverno.image.pullPolicy | string | `"IfNotPresent"` | Kyverno Image pull policy |
| kyverno.image.tag | string | `v1.10.4-n4k.nirmata.1` | Image tag (defaults to chart app version) |
| kyverno.enablePolicyExceptions| bool | `true` | Enable policyexceptions feature in Kyverno 1.9+ |
| kyverno.excludedNamespacesForWebhook | list | `[]` | Namespaces to exclude from Kyverno webhook, in addition to defaults kyverno, kube-system, nirmata, nirmata-system |
| kyverno.excludedNamespacesOverride | bool | `false` | Override exclusion of default namespaces in excludedNamespacesForWebhook parameter above|
| kyverno.helm | object | `nil` | Free form yaml section with helm parameters in Kyverno chart. Note that null values for any object in a yaml node must be specified using a special string "NULLOBJ" for that node. See all parameters [here](https://github.com/nirmata/kyverno-charts/tree/main/charts/nirmata#values). |
| policies.policySets | list | `{pod-security-restricted, rbac-best-practices}` | Default policy sets to be installed along with operator. Others are, `pod-security-baseline`, `k8s-best-practices`, and `multitenancy-best-practices` |
| awsAdapter.rbac.create | bool | false | Create RBAC resources for Kyverno AWS Adapter, if AWS Adapter is going to be enabled now (through the awsAdapter.createCR helm param below) or later |
| awsAdapter.createCR | bool | false | Enable AWS Adapter by creating its Adapter Config CR |
| awsAdapter.eksCluster.name | string | `nil` | EKS Cluster name. Required if awsAdapter.createCR is true |
| awsAdapter.eksCluster.region | string | `nil` | EKS Cluster region. Required if awsAdapter.createCR is true |
| awsAdapter.roleArn | string | `nil` | EKS Cluster roleARN. Required if awsAdapter.createCR is true |
| awsAdapter.helm | object | `nil` | Free form yaml section with helm parameters in Kyverno AWS Adapter Helm chart. Needed only if awsAdapter.createCR is true. See all parameters [here](https://github.com/nirmata/kyverno-aws-adapter/tree/main/charts/kyverno-aws-adapter#values) |
| cisAdapter.rbac.create | bool | false | Create RBAC resources for CIS Adapter, if CIS Adapter is going to be enabled now (through the cisAdapter.createCR param below) or later |
| cisAdapter.serviceAccount.create | bool | false | Create Service Account for CIS Adapter, if CIS Adapter is going to be enabled now (through the cisAdapter.createCR param below) or later |
| cisAdapter.createCR | bool | false | Enable CIS Adapter by creating its Adapter Config CR |
| cisAdapter.helm | object | `nil` | Free form yaml section with helm parameters in CIS Adapter Helm chart. Needed only if cisAdapter.createCR is true. See all parameters [here](https://github.com/nirmata/kyverno-charts/tree/main/charts/kube-bench-adapter#values) |
| imageScanAdapter.rbac.create | bool | false | Create RBAC resources for Image Scan Adapter, if it is going to be enabled now (through the imageScanAdapter.createCR helm param below) or later |
| imageScanAdapter.createCR | bool | false | Enable Image Scan Adapter by creating its Adapter Config CR |
| imageScanAdapter.helm | object | `scanAll: true` | Free form yaml section with helm parameters in Image Scan Adapter Helm chart. Needed only if imageScanAdapter.createCR is true. See all parameters [here](https://github.com/nirmata/kyverno-charts/tree/main/charts/image-scan-adapter#values) |

## (Optional) External certificate management for webhooks
Kyverno Operator uses webhooks to provide enhanced functionality such as logging user information in resource change events logged into the Kubernetes event stream, and some enhanced semantic checks for custom resources.

Webhooks need a few SSL key-certificates to work properly. By default, kyverno operator manages the creation and rotation of these. But alternatively these can be managed manually too.

###  Manual certificate management
For this, one would need to manually create the secret containing certificate and keys needed by the operator webhook, and provide the base64 encoded CA bundle to helm install command below as well. The secret should be of type `kubernetes.io/tls`, with keys `tls.crt`, `tls.key`, and `ca.crt`. The value of `ca.crt` should also be provided to the helm install command (arg `--set certManager=other --set caBundle=...`) so that it gets added to the CABundle for needed webhook configurations.
