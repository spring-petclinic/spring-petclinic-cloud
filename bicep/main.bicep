param nameseed string = 'petclinic'
param location string =  resourceGroup().location

param wavefrontApiKey string = ''

//---------Kubernetes Construction---------
module aksconst 'aks-construction/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location : location
    resourceName: nameseed
    enable_aad: true
    enableAzureRBAC : true
    registries_sku: 'Standard'
    omsagent: true
    retentionInDays: 30
    agentCount: 2
    JustUseSystemPool: true
  }
}

module acrImages 'importImages.bicep' = {
  name: 'Import-PetClinic-Images'
  params: {
    location: location
    acrName: aksconst.outputs.containerRegistryName
  }
}

//RBAC for deployment-scripts
var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'
var rbacWriter='a7ffa36f-339b-4b5c-8bdf-e2c188b2c0eb'

module kubeNamespace 'br/public:deployment-scripts/aks-run-command:1.0.1' = {
  name: 'CreateNamespace'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    managedIdentityName: 'id-AksRunCommandProxy-Admin'
    rbacRolesNeeded:[
      contributor
      rbacClusterAdmin
    ]
    commands: [
      'kubectl create namespace spring-petclinic'
    ]
  }
  dependsOn: [
    acrImages
  ]
}

module dbs 'br/public:deployment-scripts/aks-run-command:1.0.1' = {
  name: 'Install-Databases'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    rbacRolesNeeded:[
      contributor
      rbacWriter
    ]
    commands: [
      '''
      helm repo add bitnami https://charts.bitnami.com/bitnami;
      helm repo update;
      helm upgrade --install vets-db-mysql bitnami/mysql --namespace spring-petclinic --version 8.8.8 --set auth.database=service_instance_db;
      helm upgrade --install visits-db-mysql bitnami/mysql --namespace spring-petclinic --version 8.8.8 --set auth.database=service_instance_db;
      helm upgrade --install customers-db-mysql bitnami/mysql --namespace spring-petclinic --version 8.8.8 --set auth.database=service_instance_db;
      '''
    ]
  }
  dependsOn: [
    kubeNamespace
  ]
}

module app 'br/public:deployment-scripts/aks-run-command:1.0.1' = {
  name: 'Install-PetClinic-App'
  params: {
    aksName: aksconst.outputs.aksClusterName
    location: location
    rbacRolesNeeded:[
      contributor
      rbacWriter
    ]
    commands: [
      'helm upgrade --install petclinic charts/petclinic -n spring-petclinic --set wavefrontApiKey="${wavefrontApiKey}"'
    ]
  }
  dependsOn: [
    kubeNamespace
  ]
}
