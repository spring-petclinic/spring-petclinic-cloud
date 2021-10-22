# This will create a regcreds file to apply to the spring-petclinic namespace
echo "Before run script:"
echo "Need export docker password. Example: export PASSWORD=you-password-docker-account"

if [[ "$REPOSITORY_PREFIX" == *\/* ]]
then
  echo "Need export docker-username variable. Example: export USERNAME=you-docker-username"
  kubectl create secret docker-registry regcred -n spring-petclinic --docker-server="$REPOSITORY_PREFIX" --docker-username="$USERNAME" --docker-password="$PASSWORD" --docker-email="example@example.com" --dry-run=client -o yaml > ./k8s/init-namespace/02-regcreds.yaml
else
  echo "Use $REPOSITORY_PREFIX as docker-username"
  echo "Use https://index.docker.io/v1/ as docker-server"
  kubectl create secret docker-registry regcred -n spring-petclinic --docker-server="https://index.docker.io/v1/" --docker-username="$REPOSITORY_PREFIX" --docker-password="$PASSWORD" --docker-email="example@example.com" --dry-run=client -o yaml > ./k8s/init-namespace/02-regcreds.yaml
fi
