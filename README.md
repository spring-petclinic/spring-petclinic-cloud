# Spring Microservice Petclinic on AKS

## 필요도구
* git
* Github 계정 (or Azure DevOps 계정)
* Azure 계정 및 구독
* kubectl
* helm 
* mvn

## Infrastructure Provisioning

설정을 쉽게 보기 위해 Portal에서 작업수행

1. Azure Kubernetes Service 생성
   * Dev/Test
   * ACR 생성 후 Attach가능
2. Azure Container Registry 생성

3. Azure Database for mySQL
   * Flexible
   * SSL

4. Azure KeyVault생성


* AKS Constructor Helper로 Provisioning 자동화 가능
https://azure.github.io/AKS-Construction/?deploy.deployItemKey=deployArmCli

혹은

```sh
az deployment group create -g <your-resource-group>  --template-uri https://github.com/Azure/AKS-Construction/releases/download/0.9.0/main.json --parameters \
resourceName=spring-cluster \
upgradeChannel=stable \
agentCountMax=20 \
omsagent=true \
retentionInDays=30 

```


## 샘플 앱 배포

* <Kubernetes resources> > Create > Create a starter application

## Spring Petclinic Microservice 코드

* Configmap으로 Spring Config 주입
* mvn spring-boot:build-image 로 이미지 빌드가능
* 각 MSA마다 Dockerfile을 만들어서 빌드 가능

## 앱 빌드 패키징

```bash
mvn clean package -DskipTests 

export REPOSITORY_PREFIX=<your-registry>.azurecr.io/petclinic
cd spring-petclinic-customers-service && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-customers-service . && cd ../
cd spring-petclinic-vets-service && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-vets-service . && cd ../
cd spring-petclinic-visits-service && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-visits-service . && cd ../
cd spring-petclinic-api-gateway && docker build -t ${REPOSITORY_PREFIX}/spring-petclinic-api-gateway . && cd ../

```

혹은
  
```bash
export REPOSITORY_PREFIX=<your-registry>.azurecr.io/petclinic
mvn spring-boot:build-image -DREPOSITORY_PREFIX=${REPOSITORY_PREFIX} -DskipTests
```  

## 이미지 배포

```bash
az acr login --name <your-regtistry>

docker push ${REPOSITORY_PREFIX}/spring-petclinic-customers-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-vets-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-visits-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-api-gateway:latest
```

## Kuberentes 
```sh
az login 
az aks get-credentials --resource-group gmkt-rg --name spr-cluster
kubectl get nodes
```

## 네임스페이스 생성

```bash
kubectl create namespace spring-petclinic
```

## OSS mySQL DB 설치 (StatefulSet)

```sh
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install vets-db-mysql bitnami/mysql --namespace spring-petclinic --version 8 --set auth.database=service_instance_db
helm install visits-db-mysql bitnami/mysql --namespace spring-petclinic  --version 8 --set auth.database=service_instance_db
helm install customers-db-mysql bitnami/mysql --namespace spring-petclinic  --version 8 --set auth.database=service_instance_db 
```

## Role 및 Role Binding 생성

Helm Chart내 Template에 정의되어 있음. (설명 필요)

## K8S 샘플 manifests파일 설명

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

## ACR접속위한 secret생성
```bash
 kubectl create secret docker-registry regcred \
    --namespace spring-petclinic \
    --docker-server=springpetacr.azurecr.io \
    --docker-username=springpetacrsp \
    --docker-password=k4Q8Q~ebKNedjwPcoxgHqlPbhpYno.OJ6R-kSamU \
    --dry-run=client -o yaml 

```
> [!NOTE]
> 위 구문에  `> ./manifests/init-namespace/02-regcreds.yaml` 를 추가하여 yaml로 만들어 놓을 수 있음.

## Helm Chart 샘플 생성

```sh
helm create spring-petclinic
```

> [!NOTE]
> draft 도구를 사용하여 자동으로 생성할 수 있음
> Helm Library Chart를 사용하여 쉽게 생성할 수 있음

## `charts` 디렉토리 분석

## Helm Chart로 앱 배포

```sh
cd charts 
# helm upgrade --install <릴리즈명> <차트>
helm upgrade --install petclinic-release petclinic --set image.tag=latest
```





# db -> PaaS



## Tempate배포
https://ms.portal.azure.com/#create/Microsoft.Template
