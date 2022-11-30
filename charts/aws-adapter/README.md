# nirmata-kyverno-aws-adapter

## Description
The Nirmata AWS Adapter for Kyverno is a Kubernetes controller to collect the information from an EKS Cluster and generate Policy Reports for Kyverno policies that are applied on the cluster. To know more about the adapter and its implementation, checkout the repo https://github.com/nirmata/kyverno-aws-adapter

## Prerequisites
To successfully complete this guide, you will need
1. a running [EKS](https://docs.aws.amazon.com/eks/latest/userguide/create-cluster.html) cluster
1. [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
1. [Helm CLI](https://helm.sh/docs/intro/install/)

Note: Make sure your kubeconfig context is pointing to the right EKS Cluster. You can get the kubeconfig of your EKS Cluster using `aws eks update-kubeconfig --region <region-code> --name <my-cluster>`

## Installing the AWS adapter
### Create namespace
We will perform all actions in the `nirmata` namespace. Create a new namespace if it does not exist already.
```bash
cat >my-namespace.yaml <<EOF
apiVersion: v1
kind: Namespace
metadata:
  name: nirmata
EOF
kubectl apply -f my-namespace.yaml
```

### Configure IAM Role for the Service Account
The Helm chart will create a `nirmata-aws-adapter-sa` for you with necessary Roles and ClusterRoles. If you have an existing Service Account that you want to use, configure the roles appropriately.

For detailed instructions on how to configure the IAM role for service account, check out the official AWS documentation on [IAM roles for service accounts](https://docs.aws.amazon.com/eks/latest/userguide/associate-service-account-role.html)

Below are selected snippets from the official AWS documentation that you can follow to configure the IAM Role for `nirmata-aws-adapter-sa` service account.
#### Create a policy with necessary permissions
Create a new policy with the following permissions that the IAM Role will be attached to
```bash
cat >my-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:AccessKubernetesApi",
                  "eks:DescribeAddon",
                  "eks:DescribeAddonVersions",
                  "eks:DescribeCluster",
                  "eks:DescribeFargateProfile",
                  "eks:DescribeIdentityProviderConfig",
                  "eks:DescribeNodegroup",
                  "eks:DescribeUpdate",
                  "eks:ListAddons",
                  "eks:ListClusters",
                  "eks:ListFargateProfiles",
                  "eks:ListIdentityProviderConfigs",
                  "eks:ListNodegroups",
                "eks:ListTagsForResource",
                "eks:ListUpdates"
            ],
            "Resource": [
                "arn:aws:eks:*:844333597536:identityproviderconfig/*/*/*/*",
                "arn:aws:eks:*:844333597536:fargateprofile/*/*/*",
                "arn:aws:eks:*:844333597536:nodegroup/*/*/*",
                "arn:aws:eks:*:844333597536:cluster/*",
                "arn:aws:eks:*:844333597536:addon/*/*/*"
            ]
        }
    ]
}
EOF
aws iam create-policy --policy-name kyverno-aws-adapter-policy --policy-document file://my-policy.json
```

#### Export the necessary variables
```bash
aws_region=<region-of-your-eks-cluster>
cluster_name=<name-of-your-eks-cluster>
account_id=$(aws sts get-caller-identity --query "Account" --output text)

oidc_provider=$(aws eks describe-cluster --name $cluster_name --region $aws_region --query "cluster.identity.oidc.issuer" --output text | sed -e "s/^https:\/\///")

export namespace=nirmata

export service_account=nirmata-aws-adapter-sa
```

#### Create a trust relationship file
```bash
cat >trust-relationship.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::$account_id:oidc-provider/$oidc_provider"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "$oidc_provider:aud": "sts.amazonaws.com",
          "$oidc_provider:sub": "system:serviceaccount:$namespace:$service_account"
        }
      }
    }
  ]
}
EOF
```

#### Create the IAM Role
```bash
aws iam create-role --role-name kyverno-aws-adapter-role --assume-role-policy-document file://trust-relationship.json --description "iam role for the nirmata aws adapter for kyverno"
```

#### Attach policy to the role
Attach the policy that we created earlier to this newly created role

```bash
aws iam attach-role-policy --role-name kyverno-aws-adapter-role  --policy-arn=arn:aws:iam::$account_id:policy/kyverno-aws-adapter-policy
```

### Update values.yaml
Configure the variables in `charts/aws-adapter/values.yaml`
- set the namespace to `nirmata`
- set create namespace to `false` (because we have already created the namespace above)
- `roleArn` is the arn of the role created above `kyverno-aws-adapter-role`. You can either get this value from the AWS Management Console or using the AWS CLI by running `aws iam get-role --role-name kyverno-aws-adapter-role`
- set the EKS cluster name and region
- registryConfig `username` is your GitHub username
- registryConfig `password` is your GitHub Personal Access Token (See how to create a token [here](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/creating-a-personal-access-token))

### Clone the charts repo
Clone the Nirmata charts repo if not already done
```bash
git clone git@github.com:nirmata/kyverno-charts.git
cd kyverno-charts
```

### Install the Helm Chart
```bash
helm install nirmata-kyverno-aws-adapter charts/aws-adapter
```

### Verify if the installation is successful
Check the `status` field of the `<cluster-name>-config` Custom Resource in the `nirmata` namespace. For instance, if the cluster name is `eks-test`, then
```sh
kubectl get awsconfig eks-test-config -n nirmata
NAME                     CLUSTER ID   CLUSTER NAME      REGION       STATUS   KUBERNETES VERSION   PLATFORM VERSION   LAST UPDATED   LAST POLLED   LAST POLLED STATUS
eks-test-config                eks-test   ap-south-1   ACTIVE   1.24                 eks.3              37m            37m           success
```

## License

Copyright 2022.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

