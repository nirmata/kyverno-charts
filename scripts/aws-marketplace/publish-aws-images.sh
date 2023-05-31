N4K_VERSION="${N4K_VERSION:-v1.9.5-n4k.nirmata.1}"

aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 709825985650.dkr.ecr.us-east-1.amazonaws.com

docker pull ghcr.io/nirmata/kyverno:$N4K_VERSION
docker pull ghcr.io/nirmata/kyvernopre:$N4K_VERSION
docker pull ghcr.io/nirmata/cleanup-controller:$N4K_VERSION

docker tag ghcr.io/nirmata/kyverno:$N4K_VERSION 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/kyverno:$N4K_VERSION
docker tag ghcr.io/nirmata/kyvernopre:$N4K_VERSION 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/kyvernopre:$N4K_VERSION
docker tag ghcr.io/nirmata/cleanup-controller:$N4K_VERSION 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/cleanup-controller:$N4K_VERSION

docker push 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/kyverno:$N4K_VERSION
docker push 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/kyvernopre:$N4K_VERSION
docker push 709825985650.dkr.ecr.us-east-1.amazonaws.com/nirmata/cleanup-controller:$N4K_VERSION

aws ecr list-images --registry-id 709825985650 --repository-name nirmata/kyverno --region us-east-1 | grep -C3 $N4K_VERSION
aws ecr list-images --registry-id 709825985650 --repository-name nirmata/kyvernopre --region us-east-1 | grep -C3 $N4K_VERSION
aws ecr list-images --registry-id 709825985650 --repository-name nirmata/cleanup-controller --region us-east-1 | grep -C3 $N4K_VERSION
