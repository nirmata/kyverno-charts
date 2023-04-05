export HELM_EXPERIMENTAL_OCI=1
aws ecr get-login-password --region us-east-1 | helm registry login --username AWS --password-stdin 709825985650.dkr.ecr.us-east-1.amazonaws.com

VERSION=v1.10.0-07
helm package aws
helm push kyverno-chart-${VERSION}-aws.tgz oci://709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/
