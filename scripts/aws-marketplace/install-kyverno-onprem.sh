kubectl create namespace kyverno
kubectl create serviceaccount awslm-service-account --namespace kyverno

AWSMP_TOKEN=eyJhbGciOiJSUzUxMiIsInR5cCI6IkpXUyIsImtpZCI6InVzLWVhc3QtMV84OTQzMTY0OS00MmUxLTQxYjMtOWJhNy1mMDNmZDU3MWViZWEifQ.eyJzdWIiOiJlMjgyMTBiYy0yODZhLTQ0NDgtOGI1Yi1hMjBjNmE1ZDI4NjAiLCJhdWQiOiJhcm46YXdzOmxpY2Vuc2UtbWFuYWdlcjo6Mjk0NDA2ODkxMzExOmxpY2Vuc2U6bC0xYjY2YzBiNzkxODg0MmQyYTA3MTcwNGQ2NDI3YTZlYiIsInJvbGVzIjpbImFybjphd3M6aWFtOjo4NDQzMzM1OTc1MzY6cm9sZS9zZXJ2aWNlLXJvbGUvQVdTTWFya2V0cGxhY2VMaWNlbnNlVG9rZW5Db25zdW1wdGlvblJvbGUiXSwiaXNzIjoiaHR0cHM6Ly9vcGVuaWQtbGljZW5zZS1tYW5hZ2VyLmFtYXpvbmF3cy5jb20iLCJleHAiOjE2Njg3MzEzODgsImlhdCI6MTYzNzE5NTM4OH0.paxkhWkUTsE2KlM7YwoBE4QBRl-JBMVwYicVSD-5o5EFQ09BrU3MLa2j0uLRhSkTmcMKmR-SgV9F9qDKbY2CTcoM_Myo7xqLjLSt1KW2Q-bCukJNTU_-8Vlhmti1ewkJLW0ekbQpUKckGgE7KTACRmlunSouuB3DNrPmpIVCD_dNjuBFWtLGpr3dGnoSjMLTSraDdxrMzGEW_d1RWFhL7qP1VvGWuKu7QNJiSCSK2OVCnqHdE7uhmEwclmLrHbBGPmuXPi7YUYxmecvzLDr4zPDFmY_UHE88_-ymqzzMyUO8TEBmx01MTYAxrdglsKPo58jHao7Fy_L69UdBFWCn15ocfZkAjk51sarfH4USdAMI0IssNPq2dQhHbndxDhr752R8YK11mC25IaBYSRcy5nY7ptZk42jxwJ_GRmPPqoL3E9eBIIS3GI67ACQfMh6HGV80QmGlxLCDY2hDD1_38r-YpDulnrjpm6ARNWGMvaCS-TbFHWabUd87BfTrP-VO
AWSMP_ROLE_ARN=arn:aws:iam::844333597536:role/service-role/AWSMarketplaceLicenseTokenConsumptionRole

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

kubectl patch serviceaccount awslm-service-account \
--namespace kyverno \
-p '{"imagePullSecrets": [{"name": "awsmp-image-pull-secret"}]}'

