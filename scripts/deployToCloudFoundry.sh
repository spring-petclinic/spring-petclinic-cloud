echo "Creating Required Services..."
{
  cf create-service -c '{ "git": { "uri": "https://github.com/spring-petclinic/spring-petclinic-cloud-config.git", "periodic": true }, "count": 3 }' p.config-server standard config &
  cf create-service p.service-registry standard registry & 
  cf create-service p.mysql db-small customers-db &
  cf create-service p.mysql db-small vets-db &
  cf create-service p.mysql db-small visits-db &
  sleep 5
} &> /dev/null
until [ `cf service config | grep -c "succeeded"` -ge 1  ] && [ `cf service registry | grep -c "succeeded"` -ge 1  ] && [ `cf service customers-db | grep -c "succeeded"` -ge 1  ] && [ `cf service vets-db | grep -c "succeeded"` -ge 1  ] && [ `cf service visits-db | grep -c "succeeded"` -ge 1  ]
do
  echo "."
done

mvn clean package -Pcloud
cf push --no-start

cf add-network-policy api-gateway --destination-app vets-service --protocol tcp --port 8080
cf add-network-policy api-gateway --destination-app customers-service --protocol tcp --port 8080
cf add-network-policy api-gateway --destination-app visits-service --protocol tcp --port 8080

cf start vets-service & cf start visits-service & cf start customers-service & cf start api-gateway &
