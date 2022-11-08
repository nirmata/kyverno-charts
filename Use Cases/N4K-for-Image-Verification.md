#Steps for image verification

Below are the steps to verify images before deployment to Kubernetes runtime environments - 

Download the certified N4K Kyverno and adapter images to the customer's private repo.
Customize Kyverno and adapter deployment as required for the customer's environment via Helm values file (docker-registry credentials, custom CA, Proxy etc.).
Deploy Kyverno using the Helm Chart.
Deploy the adapters using the Helm Chart.
Leverage cosign or Venafi workflow to sign the images.
Deploy the image verification Kyverno policy.
Confirm image verification based on policy pass/fail.



Location and Credentials to access N4K images

Please download the Kyverno and adapter images below - 

        ghcr.io/nirmata/kyverno:v1.8.1-n4kbuild.1
        ghcr.io/nirmata/kyvernopre:v1.8.1-n4kbuild.1
        ghcr.io/nirmata/kube-rbac-proxy:v0.13.1
        ghcr.io/nirmata/nirmata-imagekey-controller:v0.1


Please use the below credentials to access N4K images - 

Username: nirmata-enterprise-for-kyverno
Password: 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

Kyverno Installation


Install the Helm charts by following the instructions here. The necessary credentials for the image repo must be passed during installation of the Helm repo to authenticate with the customer’s container registry. Set the image registry using the parameters below
 	
--set image.repository=<registry_name>>
--set image.pullSecrets.registry=<<registry_name>>
--set image.pullSecrets.username=<user> 
--set image.pullSecrets.password=<password>



For custom certs, follow the custom cert section in the [installation](https://github.com/nirmata/kyverno-charts/tree/main/charts/venafi-adapter#installation) guide and use the parameters below to set the right ca bundle path and configmap. 

 --set systemCertPath=/etc/pki/tls/certs
 --set customCAConfigMap=<<configmap_name>>


Nirmata Venafi Adapter installation: 


Install the Helm charts by following the instructions here. The necessary credentials for the image repo must be passed during installation of the Helm repo to authenticate with the customer’s container registry. Set the image registry using the parameters below






--set venafiAdapterImage=<<nirmata-imagekey-controller_image_full_path>>
--set imagePullSecret.registry=<<registry_name>>
--set imagePullSecret.username=<<user>> 
--set imagePullSecret.password=<<password>>



For custom certs, follow the custom cert section in the installation guide and use the parameters below to set the right ca bundle path and configmap.



 --set systemCertPath=/etc/pki/tls/certs
 --set customCAConfigMap=<<configmap_name>>




Validate signed images with Venafi adapter


Refer the steps here to create a password secret and CR yaml imagekey.yaml
Ensure the first job runs and downloads the specified key to configmap specified
Refer the sample policy to create a Kyverno imageverify policy referring to the configmap field
Validate  whether pods are blocked or allowed based on whether they are signed with Venafi keys.
