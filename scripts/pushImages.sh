#!/bin/bash
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-api-gateway:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-visits-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-vets-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-customers-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-admin-server:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-discovery-service:latest
docker push ${REPOSITORY_PREFIX}/spring-petclinic-cloud-config-server:latest

