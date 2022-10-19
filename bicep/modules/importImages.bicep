param acrName string 
param location string =  resourceGroup().location

var petclinicImages = [
  'docker.io/springcommunity/spring-petclinic-cloud-api-gateway:latest'
  'docker.io/springcommunity/spring-petclinic-cloud-visits-service:latest'
  'docker.io/springcommunity/spring-petclinic-cloud-vets-service:latest'
  'docker.io/springcommunity/spring-petclinic-cloud-customers-service:latest'
  'docker.io/springcommunity/spring-petclinic-cloud-admin-server:latest'
  'docker.io/springcommunity/spring-petclinic-cloud-discovery-service:latest'
  'docker.io/springcommunity/spring-petclinic-cloud-config-server:latest'
  'docker.io/wavefronthq/proxy:latest'
]

module acrImport 'br/public:deployment-scripts/import-acr:2.0.1' = {
  name: 'Import-PetClinic-Images-${acrName}'
  params: {
    acrName: acrName
    location: location
    images: petclinicImages
  }
}
