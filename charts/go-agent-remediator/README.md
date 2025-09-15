# Go Agent Remediator Helm Chart

This Helm chart deploys Remediator Service agent in a Kubernetes cluster.

## Prerequisites

Before installing the Remediator Agent, ensure you have the following prerequisites:

- A Kubernetes cluster with [Argo CD](https://argo-cd.readthedocs.io/en/stable/getting_started/)
- [Helm](https://helm.sh/docs/intro/install/)
- [kubectl](https://kubernetes.io/docs/reference/kubectl/)

## Setup

Create `nirmata` namespace
```bash
kubectl create namespace nirmata
```

#### Using Pod Identity Agent (Recommended for EKS)
Create an IAM role with a trust policy for the Pod Identity Agent.
```bash
aws iam create-role \
  --role-name remediator-agent-role \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Principal": { "Service": "pods.eks.amazonaws.com" },
        "Action": [ "sts:AssumeRole", "sts:TagSession" ]
      }
    ]
  }'
```

Give the role permission to invoke Bedrock models.
```bash
aws iam put-role-policy \
  --role-name remediator-agent-role \
  --policy-name BedrockInvokePolicy \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Sid": "BedrockInvoke",
        "Effect": "Allow",
        "Action": [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ],
        "Resource": "arn:aws:bedrock:<AWS_REGION>:<AWS_ACCOUNT_ID>:application-inference-profile/<BEDROCK_INFERENCE_PROFILE>"
      }
    ]
  }'
```

Bind the IAM role to your Kubernetes ServiceAccount using Pod Identity. Replace `<CLUSTER_NAME>` and `<ACCOUNT_ID>` with your actual cluster name and accound id.
```bash
aws eks create-pod-identity-association \
  --cluster-name <CLUSTER_NAME> \
  --namespace nirmata \
  --service-account remediator-agent \
  --role-arn arn:aws:iam::<ACCOUNT_ID>:role/remediator-agent-role
```

Verify the association.
```bash
aws eks list-pod-identity-associations \
  --cluster-name <CLUSTER_NAME>
```

#### Using AWS Credentials Secret
```bash
kubectl create secret generic aws-bedrock-credentials \
  --from-literal=aws_access_key_id=AWS_ACCESS_KEY \
  --from-literal=aws_secret_access_key=AWS_SECRET_KEY \
  --from-literal=aws_session_token=AWS_SECRET_SESSION_TOKEN \
  --namespace nirmata
```

## Installation

**Note**: Skip the `--set llm.secretRef.name="aws-bedrock-credentials"` argument in the command below if you are using the Pod Identity Agent.

```bash
helm repo add nirmata https://nirmata.github.io/kyverno-charts

helm repo update nirmata

helm install remediator nirmata/remediator-agent --devel \
  --namespace nirmata \
  --create-namespace \
  --set llm.provider="bedrock" \
  --set llm.bedrock.model="BEDROCK_INFERENCE_PROFILE" \
  --set llm.bedrock.region="AWS_REGION" \
  --set llm.secretRef.name="aws-bedrock-credentials"
```

## Configuration

### Core Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `replicaCount` | Number of controller replicas | `1` |
| `image.repository` | Container image repository | `ghcr.io/nirmata/go-agent-remediator` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `logging.verbosity` | Log verbosity level (0=info, 1=audit+info, 2=debug+audit+info) | `0` |
| `logging.enableAudit` | Enable audit logging (equivalent to verbosity >= 1) | `false` |

*Note: Image tag is automatically set to `Chart.yaml` appVersion*

### Audit Logging

To enable audit logging for compliance and troubleshooting:

```bash
# Enable audit logging only
helm install remediator charts/go-agent-remediator \
  --set logging.enableAudit=true

## Uninstalling

```bash
helm uninstall remediator -n nirmata
```

**Note:** This removes the deployment and CRDs but preserves secrets. They need to be cleaned up manually.
