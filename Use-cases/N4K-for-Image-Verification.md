## Steps for image verification

Below are the steps to verify images before deployment to Kubernetes runtime environments - 

1. Download the certified N4K Kyverno and adapter images to the customer's private repo.
2. Customize Kyverno and adapter deployment as required for the customer's environment via Helm values file (docker-registry credentials, custom CA, Proxy etc.).
3. Deploy Kyverno using the Helm Chart.
4. Deploy the adapters using the Helm Chart.
5. Leverage cosign or Venafi workflow to sign the images.
6. Deploy the image verification Kyverno policy.
7. Confirm image verification based on policy pass/fail.



## Location and Credentials to access N4K images

Please download the Kyverno and adapter images below - 

        ghcr.io/nirmata/kyverno
        ghcr.io/nirmata/kyvernopre
        ghcr.io/nirmata/kube-rbac-proxy
        ghcr.io/nirmata/nirmata-imagekey-controller


Please use the below credentials provided to you to access N4K images - 
```
Username: nirmata-enterprise-for-kyverno
Password: <token-provided-by-nirmata>
```
## Kyverno Installation


Install the Helm charts by following the instructions [here](https://github.com/nirmata/kyverno-charts/tree/main/charts/nirmata#installing-the-chart). The necessary credentials for the image repo must be passed during installation of the Helm chart to authenticate with the customer’s container registry. Set the image registry using the parameters below
``` 	
--set image.repository=<registry_name>
--set image.pullSecrets.registry=<registry_name>
--set image.pullSecrets.username=<user> 
--set image.pullSecrets.password=<password>
```


For custom Root CA, follow the custom certificates section in the [installation](https://github.com/nirmata/kyverno-charts/tree/main/charts/venafi-adapter#installation) guide and use the parameters below to set the right ca bundle path and configmap. 
```
 --set systemCertPath=/etc/pki/tls/certs
 --set customCAConfigMap=<configmap_name>
```

## Nirmata Venafi Adapter installation


Install the Helm charts by following the instructions [here](https://github.com/nirmata/kyverno-charts/tree/main/charts/venafi-adapter). The necessary credentials for the image repo must be passed during installation of the Helm chart to authenticate with the customer’s container registry. Set the image registry using the parameters below




```
--set venafiAdapterImage=<nirmata-imagekey-controller_image_full_path>
--set imagePullSecret.registry=<registry_name>
--set imagePullSecret.username=<user>
--set imagePullSecret.password=<password>
```


For custom certs, follow the custom cert section in the [installation](https://github.com/nirmata/kyverno-charts/tree/main/charts/venafi-adapter#installation) guide and use the parameters below to set the right ca bundle path and configmap.


```
 --set systemCertPath=/etc/pki/tls/certs
 --set customCAConfigMap=<configmap_name>
```



## Validate signed images with Venafi adapter


Refer the steps [here](https://github.com/nirmata/kyverno-charts/tree/main/charts/venafi-adapter#test-a-sample-policy) to create a password secret and CR yaml imagekey.yaml
Ensure the first job runs and downloads the specified key to configmap specified
Refer the sample [policy](https://github.com/dolisss/kyverno_policies/blob/main/supply-chain/verify_image_venafi.yaml) to create a Kyverno imageverify policy referring to the configmap field
Validate  whether pods are blocked or allowed based on whether they are signed with Venafi keys.
