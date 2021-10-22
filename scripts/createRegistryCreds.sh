# This will create a regcreds file to apply to the spring-petclinic namespace 
echo "Before run script:"
echo "export REPOSITORY_PREFIX=you-docker-account"
echo "export export PASSWORD=you-password-docker-account"
kubectl create secret docker-registry regcred -n spring-petclinic --docker-server="https://index.docker.io/v1/" --docker-username="$REPOSITORY_PREFIX" --docker-password="$PASSWORD" --docker-email="example@example.com" --dry-run=client -o yaml > ./k8s/init-namespace/02-regcreds.yaml
