# This will create a regcreds file to apply to the spring-petclinic namespace

if [ -z "$PASSWORD" ]
then
  echo "Need export docker password. Example: export PASSWORD=you-password-docker-account"
  exit 0
fi

if [ -z "$REPOSITORY_PREFIX" ]
then
  echo "Need export REPOSITORY_PREFIX"
  echo "If you use private registry, then REPOSITORY_PREFIX is path to you private registry. Example: export REPOSITORY_PREFIX=harbor.myregistry.com/demo"
  echo "If you use dockerhub, then REPOSITORY_PREFIX is you account on dockerhub. Example: export REPOSITORY_PREFIX=odedia"
  exit 0
fi

if [[ "$REPOSITORY_PREFIX" == *\/* ]]
then
  if [ -z "$USERNAME" ]
  then
    echo "Need export docker-username variable. Example: export USERNAME=you-docker-username"
    exit 0
  fi
  kubectl create secret docker-registry regcred -n spring-petclinic --docker-server="$REPOSITORY_PREFIX" --docker-username="$USERNAME" --docker-password="$PASSWORD" --docker-email="example@example.com" --dry-run=client -o yaml > ./k8s/init-namespace/02-regcreds.yaml
else
  echo "Use $REPOSITORY_PREFIX as docker-username"
  echo "Use https://index.docker.io/v1/ as docker-server"
  kubectl create secret docker-registry regcred -n spring-petclinic --docker-server="https://index.docker.io/v1/" --docker-username="$REPOSITORY_PREFIX" --docker-password="$PASSWORD" --docker-email="example@example.com" --dry-run=client -o yaml > ./k8s/init-namespace/02-regcreds.yaml
fi
