#!/bin/bash

#Make sure you set REPOSITOR_PREFIX with double quote for each path route. For example - my-registry.com\\/demo
cat ./k8s/*.yaml | \
sed 's/\${REPOSITORY_PREFIX}'"/${REPOSITORY_PREFIX}/g" | \
kubectl apply -f -
