
#
# Makefile for building, testing and developing Agones
#

#  __     __         _       _     _
#  \ \   / /_ _ _ __(_) __ _| |__ | | ___ ___
#   \ \ / / _` | '__| |/ _` | '_ \| |/ _ \ __|
#    \ V / (_| | |  | | (_| | |_) | |  __\__ \
#     \_/ \__,_|_|  |_|\__,_|_.__/|_|\___|___/
#

# kubectl configuration to use
KUBECONFIG ?= ~/.kube/config

# kind cluster name to use
KIND_PROFILE ?= petclinic
KIND_CONTAINER_NAME=$(KIND_PROFILE)-control-plane

kubeconfig_path := $(dir $(KUBECONFIG))
kubeconfig_file := $(notdir $(KUBECONFIG))

# Directory that this Makefile is in.
mkfile_path := $(abspath $(lastword $(MAKEFILE_LIST)))
build_path := $(dir $(mkfile_path))
helm_path := ~/.helm

ifdef DOCKER_RUN
	ensure-build-image += ensure-build-image
endif

#   ___            _           _
#  |_ _|_ __   ___| |_   _  __| | ___ ___
#   | || '_ \ / __| | | | |/ _` |/ _ \ __|
#   | || | | | (__| | |_| | (_| |  __\__ \
#  |___|_| |_|\___|_|\__,_|\__,_|\___|___/
#


include ./includes/kind.mk
