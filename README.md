# Spring Microservice Petclinic on AKS

## Infrastructure Provisioning

1. AKS Constructor Helper로 Provisioning 자동화
    * https://azure.github.io/AKS-Construction/?deploy.deployItemKey=deployArmCli


## 샘플 앱 배포

Kubernetes resources > Create > Create a starter application


```bash
# Create Resource Group
az group create -l koreacentral -n spring-cluster-rg
cd 

```bash
export REPOSITORY_PREFIX=springpetacr.azurecr.io/petclinic
cd spring-petclinic-customers-service && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-customers-service . && cd ../
cd spring-petclinic-vets-service && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-vets-service . && cd ../
cd spring-petclinic-visits-service && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-visits-service . && cd ../
cd spring-petclinic-api-gateway && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-api-gateway . && cd ../
```
권한할당

```bash
az login
az aks get-credentials --resource-group gmkt-rg --name spring-cluster
k get node
k create ns spring-petclinic
```


```bash
az acr login --name springpetacr

docker push ${REPOSITORY_PREFIX}/spring-petclinic-customers-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-vets-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-visits-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-api-gateway:latest
```
### Container Registry ID생성

> https://learn.microsoft.com/en-us/azure/container-registry/container-registry-auth-kubernetes

```bash
#!/bin/bash
# This script requires Azure CLI version 2.25.0 or later. Check version with `az --version`.

# Modify for your environment.
# ACR_NAME: The name of your Azure Container Registry
# SERVICE_PRINCIPAL_NAME: Must be unique within your AD tenant

export containerRegistry=springpetacr
export servicePrincipal=springpetacrsp

ACR_NAME=$containerRegistry
SERVICE_PRINCIPAL_NAME=$servicePrincipal

# Obtain the full registry ID
ACR_REGISTRY_ID=$(az acr show --name $ACR_NAME --query "id" --output tsv)
# echo $registryId

# Create the service principal with rights scoped to the registry.
# Default permissions are for docker pull access. Modify the '--role'
# argument value as desired:
# acrpull:     pull only
# acrpush:     push and pull
# owner:       push, pull, and assign roles
PASSWORD=$(az ad sp create-for-rbac --name $SERVICE_PRINCIPAL_NAME --scopes $ACR_REGISTRY_ID --role acrpull --query "password" --output tsv)
USER_NAME=$(az ad sp list --display-name $SERVICE_PRINCIPAL_NAME --query "[].appId" --output tsv)

# Output the service principal's credentials; use these in your services and
# applications to authenticate to the container registry.
echo "Service principal ID: $USER_NAME"
echo "Service principal password: $PASSWORD"


```


### ACR접속위한 secret생성
 kubectl create secret docker-registry regcred \
    --namespace spring-petclinic \
    --docker-server=springpetacr.azurecr.io \
    --docker-username=springpetacrsp \
    --docker-password=k4Q8Q~ebKNedjwPcoxgHqlPbhpYno.OJ6R-kSamU \
    --dry-run=client -o yaml > ./k8s/init-namespace/02-regcreds.yaml


```
cd charts && helm upgrade --install petclinic petclinic


mvn spring-boot:build-image -Pk8s -DREPOSITORY_PREFIX=${REPOSITORY_PREFIX} && ./scripts/pushImages.sh

# Deploy template with in-line parameters
az deployment group create -g spring-cluster-rg  --template-uri https://github.com/Azure/AKS-Construction/releases/download/0.9.0/main.json --parameters \
	resourceName=spring-cluster \
	upgradeChannel=stable \
	agentCountMax=20 \
	omsagent=true \
	retentionInDays=30 
	# ingressApplicationGateway=true

```

az aks get-credentials -n aks-spring-cluster -g spring-cluster-rg


helm upgrade --install petapp ${petClinicHelmUri} -n spring-petclinic 

# db -> PaaS
```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install vets-db-mysql bitnami/mysql --namespace spring-petclinic --version 8 --set auth.database=service_instance_db
helm install visits-db-mysql bitnami/mysql --namespace spring-petclinic  --version 8 --set auth.database=service_instance_db
helm install customers-db-mysql bitnami/mysql --namespace spring-petclinic  --version 8 --set auth.database=service_instance_db 
```


## Tempate배포
https://ms.portal.azure.com/#create/Microsoft.Template
