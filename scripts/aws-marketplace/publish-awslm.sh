AWSLM_VERSION="${AWSLM_VERSION:-0.1-rc4}"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 709825985650.dkr.ecr.us-east-1.amazonaws.com

docker tag ghcr.io/nirmata/awslm:$AWSLM_VERSION 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/awslm:$AWSLM_VERSION
