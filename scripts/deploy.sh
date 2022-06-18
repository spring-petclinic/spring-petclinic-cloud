#!/bin/bash

aws configure set default.region us-east-1
aws configure set default.output json
export REPOSITORY_PREFIX=springcommunity
export LAB_ROLE=arn:aws:iam::218984672742:role/LabRole
export SUBNET_A=subnet-050c939600d1752a6
export SUBNET_B=subnet-07a651bbf4cd7f1ba

# Creating cluster and nodes

aws eks create-cluster \
	--region us-east-1 \
	--name petclinic-cluster \
	--kubernetes-version 1.21 \
	--role-arn $LAB_ROLE \
	--resources-vpc-config subnetIds=$SUBNET_A,$SUBNET_B
	
while : ; do
	status=$(aws eks describe-cluster \
	--region us-east-1 \
	--name petclinic-cluster \
	--query "cluster.status")
	if [ "$status" == "\"CREATING\"" ]; then
		echo "Cluster not ready yet..."
	else
		echo "Cluster ready!"
		break
	fi
	sleep 10
done

aws eks update-kubeconfig --name petclinic-cluster

aws eks create-nodegroup \
	--cluster-name petclinic-cluster \
	--nodegroup-name workers \
	--node-role $LAB_ROLE \
	--subnets $SUBNET_A $SUBNET_B \
	--scaling-config minSize=2,maxSize=2,desiredSize=2

while : ; do
	status=$(aws eks describe-nodegroup \
    --cluster-name petclinic-cluster \
    --nodegroup-name workers \
    --query "nodegroup.status")
	if [ "$status" == "\"CREATING\"" ]; then
		echo "Node group not ready yet..."
	else
		echo "Node group ready!"
		break
	fi
	sleep 10
done

# Istio setup

istioctl install --set profile=demo
kubectl label namespace spring-petclinic istio-injection=enabled
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/jaeger.yaml

# kubectl -n istio-system get pods
# kubectl -n istio-system get svc
# kubectl -n istio-system get svc istio-ingressgateway

# Setting things up in Kubernetes

kubectl apply -f k8s/init-namespace/
kubectl apply -f k8s/init-services

# Verification of services:
# > kubectl get svc -n spring-petclinic
# NAME                TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)             AGE
# api-gateway         LoadBalancer   10.7.250.24    <pending>     80:32675/TCP        36s
# customers-service   ClusterIP      10.7.245.64    <none>        8080/TCP            36s
# vets-service        ClusterIP      10.7.245.150   <none>        8080/TCP            36s
# visits-service      ClusterIP      10.7.251.227   <none>        8080/TCP            35s

# Setting up databases (helm required)

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install vets-db-mysql bitnami/mysql --namespace spring-petclinic --set auth.database=service_instance_db
helm install visits-db-mysql bitnami/mysql --namespace spring-petclinic --set auth.database=service_instance_db
helm install customers-db-mysql bitnami/mysql --namespace spring-petclinic --set auth.database=service_instance_db

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.8.0/cert-manager.yaml
kubectl apply -f https://github.com/open-telemetry/opentelemetry-operator/releases/latest/download/opentelemetry-operator.yaml

# Deploy to Kubernetes

cat ./k8s/*.yaml | \
sed 's#\${REPOSITORY_PREFIX}'"#${REPOSITORY_PREFIX}#g" | \
kubectl apply -f -

kubectl apply -f k8s/otel/collector.yaml
kubectl apply -f k8s/otel/instrumentation.yaml

# Verification of deployment
# > kubectl get pods -n spring-petclinic 
# NAME                                 READY   STATUS    RESTARTS   AGE
# api-gateway-585fff448f-q45jc         1/1     Running   0          4m20s
# customers-db-mysql-0                 1/1     Running   0          11m
# customers-service-5d7d686654-kpcmx   1/1     Running   0          4m19s
# vets-db-mysql-0                      1/1     Running   0          11m
# vets-service-85cb8677df-l5xpj        1/1     Running   0          4m2s
# visits-db-mysql-0                    1/1     Running   0          11m
# visits-service-654fffbcc7-zj2jw      1/1     Running   0          4m2s

# Getting external ip of API Gateway
# kubectl get svc -n spring-petclinic api-gateway
# NAME          TYPE           CLUSTER-IP    EXTERNAL-IP      PORT(S)        AGE
# api-gateway   LoadBalancer   10.7.250.24   34.1.2.22   80:32675/TCP   18m

# restart all pods to apply instrumentation
kubectl get pods -n default --no-headers=true --namespace spring-petclinic \
| awk '/api-gateway|customers-service|vets-service|visits-service/{print $1}'\
| xargs  kubectl delete -n default pod --namespace spring-petclinic

while : ; do
  EXTERNAL_IP=$(kubectl get svc -n spring-petclinic api-gateway | sed -n '2p' | awk '{ print $4 }')
  curl $EXTERNAL_IP > /dev/null
  if (( $? == 0 )); then
    echo $EXTERNAL_IP
    break
  else
    echo "External IP unreachable, retrying..."
  fi
done
