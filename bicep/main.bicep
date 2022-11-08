param nameseed string = 'petclinic'
param location string =  resourceGroup().location

param wavefrontApiKey string = ''

//---------Kubernetes Construction---------
module aksconst 'infra/bicep/main.bicep' = {
  name: 'aksconstruction'
  params: {
    location : location
    resourceName: nameseed
    enable_aad: true
    enableAzureRBAC : true
    registries_sku: 'Basic'
    omsagent: true
    retentionInDays: 30
    agentCount: 2
    JustUseSystemPool: false
    azureKeyvaultSecretsProvider: true
    ingressApplicationGateway: true
    appGWcount: 1    
    appGWsku: 'Standard_v2'
  }
}

//RBAC for deployment-scripts
var contributor='b24988ac-6180-42a0-ab88-20f7382dd24c'
var rbacClusterAdmin='b1ff04bb-8a4e-4dc4-8eb5-8693973ce19b'

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

}

