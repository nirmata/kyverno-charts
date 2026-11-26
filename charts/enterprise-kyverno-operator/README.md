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
| nameOverride | string | `nil` | Override chart name |
| fullnameOverride | string | `nil` | Override full release name |
| namespace | string | `nil` | Target namespace for operator resources (defaults to release namespace) |
| enableWebhook | bool | `true` | Enable operator webhooks |
| certManager | string | `operator` | Webhook cert management: `operator`, `cert-manager`, or `other` |
| caBundle | string | `nil` | CA bundle when `certManager=other` |
| licenseKey | string | `nil` | License key (required) |
| apiKey | string | `nil` | License server API key |
| apiAndLicenseSecretExists | bool | `false` | Set `true` if license/api secrets are pre-created |
| profile | string | `prod` | Operator profile: `dev` or `prod` |
| globalLabels | map | `{}` | Labels added to all resources |
| globalAnnotations | map | `{}` | Annotations added to all resources |
| image.repository | string | `ghcr.io/nirmata/nirmata-kyverno-operator` | Operator image repository |
| image.tag | string | `nil` | Operator image tag (defaults to chart appVersion) |
| image.pullPolicy | string | `IfNotPresent` | Image pull policy |
| image.pullSecrets.create | bool | `false` | Create a pull secret |
| image.pullSecrets.name | string | `image-pull-secret` | Pull secret name |
| image.pullSecrets.registry | string | `ghcr.io` | Registry hostname used in pull secret |
| image.pullSecrets.username | string | `nil` | Registry username for pull secret |
| image.pullSecrets.password | string | `nil` | Registry password for pull secret |
| rbac.create | bool | `true` | Create RBAC resources |
| rbac.operatorHasAdminPerms | bool | `false` | Use cluster-admin for operator RBAC |
| rbac.serviceAccount.create | bool | `true` | Create service account |
| rbac.serviceAccount.name | string | `nil` | Use an existing service account name |
| policySet.allowReportsRbac | bool | `false` | Let a Cluster-scope PolicySet apply a read-only ClusterRole that Kyverno aggregates into its reports controller (labelled `rbac.kyverno.io/aggregate-to-reports-controller: "true"`, `get`/`list`/`watch` verbs only, no wildcard or exec/proxy resources, no other `aggregate-to-*` label, no `aggregationRule`, not aggregated by any other role), without giving the operator cluster-admin (`rbac.operatorHasAdminPerms` stays `false`). The operator only creates, updates or deletes roles it owns (annotation `policies.nirmata.io/reports-rbac-owner`). Adds to the operator ClusterRole cluster-wide `get`/`list`/`watch` on everything (Secrets included) and `create`/`update`/`patch`/`delete` on all ClusterRoles. See [Applying reports RBAC from a PolicySet](#applying-reports-rbac-from-a-policyset) |
| kyverno.createCR | bool | `true` | Create default `KyvernoConfig` CR |
| kyverno.nameOverride | string | `kyverno` | Name override for Kyverno objects (internal helper) |
| kyverno.fullnameOverride | string | `kyverno` | Fullname override for Kyverno objects (internal helper) |
| kyverno.namespace | string | `kyverno` | Namespace where Kyverno runs |
| policies.chartRepoUsername | string | `nil` | Username for Nirmata policies Helm repo |
| policies.chartRepoPassword | string | `nil` | Password for Nirmata policies Helm repo (stored in secret) |
| policies.policySets | list/string | `"[]"` | Comma-separated policy sets to create (profile provides defaults) |
| customCAConfigMap | string | `nil` | ConfigMap name containing `custom-ca.pem` |
| customCACert | string | `""` | CA cert PEM (inline) to generate a ConfigMap |
| systemCertPath | string | `/etc/ssl/certs` | Path where CA bundle will be mounted |
| service.port | int | `80` | Service port for the webhook service |
| resources | map | `{}` | Container resources (e.g., limits/requests) |
| envVars | list | `[]` | Extra environment variables for operator container |
| autoscaling.enabled | bool | `false` | If true, external HPA can manage replicas |
| defaultNodeSelector | map | `{"kubernetes.io/os": "linux"}` | Default nodeSelector for all chart pods (operator, pre-delete Job, test Pod); `nodeSelector` keys override it, `null` disables it |
| nodeSelector | map | `{}` | Pod nodeSelector, merged over `defaultNodeSelector` |
| tolerations | list | `[]` | Pod tolerations |
| affinity | map | `{}` | Pod affinity |
| cloudPlatform | string | `""` | Optional platform hint (e.g., `eks`) |

## Applying reports RBAC from a PolicySet

Kyverno's reports controller needs `get`, `list` and `watch` on every kind that a background-scanned policy matches, for example CertificateSigningRequests, Secrets, RoleBindings, PersistentVolumes or FlowSchemas. Kyverno aggregates every ClusterRole labelled `rbac.kyverno.io/aggregate-to-reports-controller: "true"` into the permissions of its reports controller, so a PolicySet can ship that role next to the policies that need it.

By default the operator has no RBAC write permission (`rbac.operatorHasAdminPerms=false`), so it skips every RBAC object of a PolicySet (Role, ClusterRole, RoleBinding, ClusterRoleBinding, ServiceAccount). `policySet.allowReportsRbac` is an opt-in that lets a PolicySet apply exactly one kind of RBAC object, without cluster-admin. It is **off by default**.

```yaml
policySet:
  allowReportsRbac: true   # sets --allow-reports-rbac=true on the operator
```

### What is allowed

A ClusterRole is applied only when all of these hold; anything else is skipped:

- `apiVersion: rbac.authorization.k8s.io/v1` and `kind: ClusterRole`
- the name is set, does not start with `system:` and is not `cluster-admin`, `admin`, `edit` or `view` (these are refused even when no such role exists in the cluster)
- the label `rbac.kyverno.io/aggregate-to-reports-controller` is set to the string `"true"`
- no other `aggregate-to-*` label is present: any label whose name starts with `aggregate-to-` (for example `rbac.authorization.k8s.io/aggregate-to-view`, `-edit`, `-admin` or `rbac.kyverno.io/aggregate-to-background-controller`, whatever its value) is refused, because Kubernetes would otherwise aggregate the role into the built-in `view`/`edit`/`admin` roles and Kyverno into its other controllers
- every rule has verbs and they are only `get`, `list` and `watch` (exact and case-sensitive: `*`, `GET`, `create`, `escalate`, ... are refused)
- no rule names a wildcard resource (`*`, `*/proxy`, `pods/*`) or one of the subresources `nodes/proxy`, `services/proxy`, `pods/proxy`, `pods/exec`, `pods/attach` and `pods/portforward`: a plain `get` on them runs commands or proxies requests, so the role would not be read-only in effect. `apiGroups` and `resourceNames` are not restricted
- there is no `aggregationRule`, not even an empty one: Kubernetes fills the rules of an aggregated role from other roles, which would bypass the verb check
- there is no `nonResourceURLs`

Before it writes the role the operator also checks, against the ClusterRoles in the cluster, that no other role would aggregate it: the role's labels must not match a `clusterRoleSelectors` entry (`matchLabels` or `matchExpressions`) of the `aggregationRule` of any other ClusterRole. That is what keeps the role out of Kyverno's admission, background and cleanup controllers (they select by the `app.kubernetes.io/component`, `instance` and `part-of` labels), of the built-in `view`/`edit`/`admin` roles and of any third-party aggregating role. The only roles that are ignored are the reports-controller aggregators, that is a role one of whose selectors has `matchLabels` `rbac.kyverno.io/aggregate-to-reports-controller: "true"`: the role is meant to be aggregated there. A role that would be aggregated elsewhere is skipped, with a message naming the aggregating role. The check fails closed: an empty selector (`{}`) or one that is not a valid selector counts as matching, and when the ClusterRoles cannot be listed the role is not applied and the sync is retried.

A minimal example:

```yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: nirmata-policies-reports
  labels:
    rbac.kyverno.io/aggregate-to-reports-controller: "true"
rules:
  - apiGroups: ["certificates.k8s.io"]
    resources: ["certificatesigningrequests"]
    verbs: ["get", "list", "watch"]
  - apiGroups: [""]
    resources: ["secrets", "persistentvolumes"]
    verbs: ["get", "list", "watch"]
```

Every other RBAC object is still skipped. A ClusterRole that is refused is logged with the reason (the object and the violated rules) at Info level, once per operator process; every repeat, and every other skipped RBAC object (Role, RoleBinding, ServiceAccount, ... of a Helm chart or a Git source), is logged at debug level (`V(1)`). A role that is applied is not a policy: it is not counted in `status.policies.totalPolicies` and has no entry in `status.policies.policiesStatus` (see [install-rbac](#behavior) for the one case where a Helm source counts it).

### Ownership

The operator marks every role it applies with the annotation `policies.nirmata.io/reports-rbac-owner: <PolicySet namespace>/<PolicySet name>`. A ClusterRole name is shared by the whole cluster, so the operator touches only roles it owns:

- A missing role is created, with a plain create.
- A role that carries exactly that annotation is updated, pruned (removed from the source) and deleted (PolicySet deleted, or Cluster scope switched to namespace scope).
- Any other existing role is **never** overwritten or deleted: a hand-made role, even one that carries the reports label, and the role of another PolicySet. It is reported as skipped, with a warning in the PolicySet's sync error message ("applied with warnings", `N objects skipped: ClusterRole <name> exists and is not owned by this PolicySet; rename it or delete it`), and the rest of the PolicySet is applied. The label is not proof of ownership: only the annotation is.
- The annotation is set by the operator, never taken from the policy files.
- For Git/Kustomize sources the ownership check on prune and uninstall applies to every ClusterRole the PolicySet applied, even with `rbac.operatorHasAdminPerms=true`.

To migrate a hand-made workaround role (the one you created before this option existed) to a PolicySet, delete it or rename it: the operator then creates its own. After a conflict is cleared, the role is created on the next sync when the PolicySet has `autoDeployChanges` enabled (the default); with `autoDeployChanges: false` it is created only on the next operator restart or change of the PolicySet's scope or `targetNamespaces`.

The writes are made safe against races. The role is read first; a missing role is created with create-if-missing (so a role that appeared in between is never overwritten, the create fails with "already exists"); an owned role is updated with the `resourceVersion` that was read, and deleted with the UID and `resourceVersion` that were read as preconditions (one re-check after a `409 Conflict`). A write that loses a race is not an overwrite: it fails, is reported, and is retried on the next reconcile.

The guard fails closed. If the operator cannot read the live ClusterRole (any API error other than "not found") it does not apply the role, the PolicySet reports the error and the sync is retried; the role's earlier record is kept so it is neither forgotten nor pruned meanwhile. A prune or an uninstall that cannot read the role does not delete it either (a prune is retried, an uninstall logs the error). The same holds when the operator does not know which PolicySet it works for: it then applies nothing and never adopts or deletes an existing role.

### RBAC the chart adds

With the value on, the operator ClusterRole gains two rules and the operator Deployment gets `--allow-reports-rbac=true`:

```yaml
- apiGroups: ["*"]
  resources: ["*"]
  verbs: ["get", "list", "watch"]
- apiGroups: ["rbac.authorization.k8s.io"]
  resources: ["clusterroles"]
  verbs: ["create", "update", "patch", "delete"]
```

The chart does not grant `escalate` or `bind` (nor `impersonate`), and none is needed. Kubernetes only lets a subject create or update a ClusterRole whose permissions it already holds itself. The allow-list admits nothing but `get`/`list`/`watch` rules, and the cluster-wide read rule above already covers those, so the operator can create the role without escalating. It can only grant read verbs, but read on everything it holds.

**Blast radius.** Enable the option only if you accept the following:

- With the value on, the operator's ServiceAccount is highly privileged. The `*`/`*` rule gives it cluster-wide `get`, `list` and `watch` on every resource, Secrets included, and on every subresource, such as `nodes/proxy`.
- A role may grant read of Secrets, and of any other resource that is not a wildcard or an exec/proxy subresource, to the reports controller: the allow-list does not restrict which resources or API groups a role may read. Whoever can edit a Cluster-scope PolicySet can therefore grant Kyverno's reports controller read access to those resources in the whole cluster.
- The write rule covers **all** ClusterRoles: Kubernetes cannot limit it with `resourceNames` here, because the role names come from the PolicySets and are not known in advance. A compromised operator could delete or overwrite any ClusterRole.
- The [ownership](#ownership) guard and the allow-list are safeguards in the operator's code, not RBAC limits: they do not restrict what the operator's service account is allowed to do.

With the value off, unset or `null` the chart renders exactly as it did before the value existed. With the value on but `rbac.create=false` the chart passes the flag to the operator but renders no RBAC for it, so every apply of a role is Forbidden until you grant the operator the permissions above yourself.

### Behavior

- Works with `rbac.operatorHasAdminPerms=false`, which is the point of the option.
- With `--install-rbac` (`rbac.operatorHasAdminPerms=true`) the Helm path keeps applying every other RBAC object exactly as before and counts it in the status. A role that passes the allow-list is still guarded: the validator, the ownership guard and the aggregation check apply to it, in a Helm chart as well. Git/Kustomize sources, which never applied RBAC, additionally get the allow-listed ClusterRole when the value is on, whatever `--install-rbac` says: such a role always gets the validator, the ownership guard and the aggregation check, and is always left out of the status counts.
- Only Cluster-scope PolicySets can apply the role. A namespace-scoped PolicySet can never apply a ClusterRole: the role is refused (the kind is not allowed in a namespace-scoped PolicySet) and reported in the PolicySet's sync error message. When a Cluster-scope PolicySet that applied the role is switched to namespace scope, the role it applied is removed, unless it is not owned any more (see [ownership](#ownership)).
- It works for Helm and for Git/Kustomize PolicySets.
- Lifecycle: the role is applied together with the policies, updated when its source changes, deleted when it is removed from the source (or stops passing the allow-list), and deleted when the PolicySet is deleted.
- A Git source with a file that cannot be parsed: while any file of the source fails to parse, the operator cannot tell a role whose file just turned into invalid YAML from a role that was removed, so it keeps every stale reports ClusterRole key in its record and leaves the live roles untouched (no write, no delete). It keeps no state in memory, so this survives an operator restart. A log line says so (Info, once per operator process for the same roles). Roles of files that were removed are pruned again as soon as every file parses. A role file that parses but is no longer allowed by the allow-list is not an invalid file: that role is removed. Deleting the PolicySet while a file is unparseable leaves that role in the cluster, because the operator only deletes what it renders: delete it by hand.

### Turning the value off, and downgrades

The role stays in the cluster when the value is turned off, or the PolicySet no longer ships it: the operator may not manage RBAC any more (the chart also drops its permission to write ClusterRoles), so delete the roles by hand. The operator does not try to delete a stale role in that case: it logs an Info line (naming the role, to be deleted by hand), drops the stale entry from its record and carries on, instead of failing on every sync. Remove the roles from the PolicySets first if you want the operator to delete them.

A downgrade to an operator image that does not have this feature cannot be handled in code, and the chart rule is gone too: delete the roles first.

### Caveats

- The roles are only as safe as the allow-list and the ownership guard make them; see the blast radius above.
- The background controller aggregate label (`rbac.kyverno.io/aggregate-to-background-controller`) is not supported: a role that carries it is refused.
- The Kyverno CR and the cert-manager rendering are unaffected.

## (Optional) External certificate management for webhooks
Kyverno Operator uses webhooks to provide enhanced functionality such as logging user information in resource change events logged into the Kubernetes event stream, and some enhanced semantic checks for custom resources.

Webhooks need a few SSL key-certificates to work properly. By default, kyverno operator manages the creation and rotation of these. But alternatively these can be managed manually too.

###  Manual certificate management
For this, one would need to manually create the secret containing certificate and keys needed by the operator webhook, and provide the base64 encoded CA bundle to helm install command below as well. The secret should be of type `kubernetes.io/tls`, with keys `tls.crt`, `tls.key`, and `ca.crt`. The value of `ca.crt` should also be provided to the helm install command (arg `--set certManager=other --set caBundle=...`) so that it gets added to the CABundle for needed webhook configurations.
