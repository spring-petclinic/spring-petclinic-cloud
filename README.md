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

* 샘플앱 살표보기

```sh
kubectl run busybox -i --tty --image=busybox --restart=Never --rm -- sh
kubectl run curl --rm -i --tty --image=curlimages/curl -- sh
kubectl logs <pod>
kubectl describe po <pod>
kubectl get po -o yaml
```

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

# helm upgrade --install <릴리즈명> <차트>
helm upgrade --install petclinic-release charts/petclinic --set image.tag=latest
```

## API 테스트

`test.http` 파일로 API테스트

```sh
kubectl run curl --rm -i --tty --image=curlimages/curl:7.73.0 -- sh
	# curl http://customers-service.spring-petclinic.svc.cluster.local:8080/owners
```

## Azure KeyVault

* KeyVault의 Secret을 사용하기 위해 [Kubernetes CSI(Container Storage Interface)](https://kubernetes-csi.github.io/docs/)를 사용함

* AKS에서 CSI와 Managed ID를 활성화 시킴

```bash
export aks=spr-cluster
export rg=gmkt-rg
az aks enable-addons -a azure-keyvault-secrets-provider -n $aks -g $rg
az aks update -n $aks -g $rg --enable-managed-identity
```

* 클러스터에 `--enable-managed-identity`를 활성화하면 아래와 같이 objectId (Managed ID)를 얻을 수 있음.
  
```json
 "identity": {
        "clientId": "90e35a2c-3a2e-495a-88a6-9ca1cd5d710a",
        "objectId": "668c37cb-ee54-44bf-bc42-03e420240b5d",
        "resourceId": "/subscriptions/2f2d6dff-65ac-45fc-9180-bad1e786a763/resourcegroups/~~~~"
     }
```

* KeyVault 서비스에 secret permission을 위 AKS managed ID에 할당함
  
```bash
    az keyvault set-policy -n <your-keyvault> --secret-permissions get --object-id 668c37cb-ee54-44bf-bc42-03e420240b5d
```

* CSI Manifest 파일 [secretproviderclass](manifests/secretproviderclass.yml)을 수정.
  * `userAssignedIdentityID`에 위 Managed ID의 `clientId`를 입력
  * `tenantID`: 계정의 TenantID 입력
    > `az account list` 로 확인

    ```yaml
    (생략)
    ...
    parameters:
    usePodIdentity: "false"
    useVMManagedIdentity: "true"
    userAssignedIdentityID: "<clientId>"
    keyvaultName: "<your-keyvault>"
    cloudName: ""
    objects:  |
      array:
        - |
          objectName: mysql-url
          objectType: secret                     
          objectVersion: ""                    
        - |
          objectName: mysql-user
          objectType: secret
          objectVersion: ""
        - |
          objectName: mysql-pass
          objectType: secret
          objectVersion: "" 
    tenantId: "<your-tenant-id>"
    ```
### Secret 저장

```sh
az keyvault secret set --vault-name <your-keyvault> --name mysql-url --value "jdbc:mysqlql://<your-mysql-name>.mysql.database.azure.com/petclinic?sslmode=verify-full&&sslfactory=org.mysqlql.ssl.SingleCertValidatingFactory&sslfactoryarg=classpath:BaltimoreCyberTrustRoot.crt.pem"

    az keyvault secret set --vault-name <your-keyvault> --name mysql-user --value <user>@<your-mysql-name>

    az keyvault secret set --vault-name <your-keyvault> --name mysql-pass --value <password>
```

## Azure Database for mySQL
Flexible db로 생성

`service_instance_db` DB생성. 마이크로서비스 별로 DB분리

az mysql flexible-server db create --resource-group gmkt-rg --server-name mysqlandy --database-name visits_db
az mysql flexible-server db create --resource-group gmkt-rg --server-name mysqlandy --database-name vets_db
az mysql flexible-server db create --resource-group gmkt-rg --server-name mysqlandy --database-name customers_db

              

## Application Insights

## Application Gateway
