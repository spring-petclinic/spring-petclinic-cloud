#   _  ___           _
#  | |/ (_)_ __   __| |
#  | ' /| | '_ \ / _` |
#  | . \| | | | | (_| |
#  |_|\_\_|_| |_|\__,_|

# creates a kind cluster for use with spring-petclinic-kubernetes
# Kind stand for Kubernetes IN Docker
# You can change the cluster name using KIND_PROFILE env var
kind-test-cluster: DOCKER_RUN_ARGS+=--network=host
kind-test-cluster:
	@if [ -z $$(kind get clusters | grep $(KIND_PROFILE)) ]; then\
		echo "Could not find $(KIND_PROFILE) cluster. Creating...";\
		kind create cluster --name $(KIND_PROFILE) --image kindest/node:v1.12.9 --wait 5m;\
	fi
