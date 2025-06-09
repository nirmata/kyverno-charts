kubectl create namespace kyverno
kubectl create serviceaccount kyverno-admission-controller --namespace kyverno

AWSMP_TOKEN=<AWS Marketplace token>
AWSMP_ROLE_ARN=arn:aws:iam::<account-id>:role/service-role/AWSMarketplaceLicenseTokenConsumptionRole

kubectl create secret generic awsmp-license-token-secret \
--from-literal=license_token=$AWSMP_TOKEN \
--from-literal=iam_role=$AWSMP_ROLE_ARN \
--namespace kyverno

AWSMP_ACCESS_TOKEN=$(aws license-manager get-access-token \
    --output text --query '*' --token $AWSMP_TOKEN --region us-east-1)

AWSMP_ROLE_CREDENTIALS=$(aws sts assume-role-with-web-identity \
                --region 'us-east-1' \
                --role-arn $AWSMP_ROLE_ARN \
                --role-session-name 'AWSMP-guided-deployment-session' \
                --web-identity-token $AWSMP_ACCESS_TOKEN \
                --query 'Credentials' \
                --output text)   
                
export AWS_ACCESS_KEY_ID=$(echo $AWSMP_ROLE_CREDENTIALS | awk '{print $1}' | xargs)
export AWS_SECRET_ACCESS_KEY=$(echo $AWSMP_ROLE_CREDENTIALS | awk '{print $3}' | xargs)
export AWS_SESSION_TOKEN=$(echo $AWSMP_ROLE_CREDENTIALS | awk '{print $4}' | xargs)

kubectl create secret docker-registry awsmp-image-pull-secret \
--docker-server=709825985650.dkr.ecr.us-east-1.amazonaws.com \
--docker-username=AWS \
--docker-password=$(aws ecr get-login-password --region us-east-1) \
--namespace kyverno

kubectl patch serviceaccount kyverno-admission-controller \
--namespace kyverno \
-p '{"imagePullSecrets": [{"name": "awsmp-image-pull-secret"}]}'

