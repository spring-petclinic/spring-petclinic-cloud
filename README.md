# Spring Microservice Petclinic on AKS

## Infrastructure Provisioning

1. AKS Constructor Helper로 Provisioning 자동화
    * https://azure.github.io/AKS-Construction/?deploy.deployItemKey=deployArmCli

```bash
# Create Resource Group
az group create -l koreacentral -n spring-cluster-rg

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


helm upgrade --install petapp ${petClinicHelmUri} -n spring-petclinic --set wavefrontApiKey="${wavefrontApiKey}"


helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install vets-db-mysql bitnami/mysql --namespace spring-petclinic --version 8 --set auth.database=service_instance_db
helm install visits-db-mysql bitnami/mysql --namespace spring-petclinic  --version 8 --set auth.database=service_instance_db
helm install customers-db-mysql bitnami/mysql --namespace spring-petclinic  --version 8 --set auth.database=service_instance_db