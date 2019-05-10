OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
SHELL = /bin/bash

default: build

.PHONY: build
.PHONY: publish
.PHONY: run
.PHONY: shell
.PHONY: clustername
.PHONY: lint

IMAGE_NAME=test-mysql-new-cluster

TEST_FILES = $(shell find ./test -name "*")
#TEST_SHELL_FILES = $(shell find ./test -name "*.sh" )
TEMP_FILES = $(shell find ./temp -name "*" | grep -v "/phony/" )

temp/phony/cfplatformeng:
	mkdir -p temp/phony/cfplatformeng

temp/phony/cfplatformeng/$(IMAGE_NAME): temp/phony/cfplatformeng Dockerfile $(TEST_FILES) $(TEMP_FILES)
	docker build . -t cfplatformeng/$(IMAGE_NAME)
	touch temp/phony/cfplatformeng/$(IMAGE_NAME)

temp/configkube: ../../configkube/set-context
	mkdir -p temp
	cp ../../configkube/set-context temp/configkube

build: lint temp/configkube temp/phony/cfplatformeng/$(IMAGE_NAME)

publish:
#	echo "PKS licensing is blocking this"
	docker push cfplatformeng/$(IMAGE_NAME)

clustername:
	echo "Cluster Name is: ${K8S_CLUSTER}"

k8s-cluster-info:
	if [ -z "${K8S_CLUSTER}" ] ; then echo "K8S_CLUSTER must be specified"; exit 1; fi

temp/gke/get-kubeconfig.sh:	../gke-clusters/get-kubeconfig.sh
	mkdir -p temp/gke
	cp ../gke-clusters/get-kubeconfig.sh temp/gke/get-kubeconfig.sh

temp/gke/create-cluster.sh:	../gke-clusters/create-cluster.sh temp/gke/get-kubeconfig.sh
	mkdir -p temp/gke
	cp ../gke-clusters/create-cluster.sh temp/gke/create-cluster.sh

temp/gke/delete-cluster.sh:	../gke-clusters/delete-cluster.sh
	mkdir -p temp/gke
	cp ../gke-clusters/delete-cluster.sh temp/gke/delete-cluster.sh

temp/pks/cluster.sh: ../pks-clusters/cluster.sh
	mkdir -p temp/pks
	cp ../pks-clusters/cluster.sh temp/pks/cluster.sh

temp/pks/create-cluster.sh:	temp/pks/cluster.sh ../pks-clusters/create-cluster.sh
	cp ../pks-clusters/create-cluster.sh temp/pks/create-cluster.sh

temp/pks/delete-cluster.sh:	temp/pks/cluster.sh ../pks-clusters/delete-cluster.sh
	cp ../pks-clusters/delete-cluster.sh temp/pks/delete-cluster.sh

./pci/k8s/config:

create-gke-cluster:	k8s-cluster-info  temp/gke/create-cluster.sh ./pci/k8s/config
	temp/gke/create-cluster.sh $(K8S_CLUSTER)

create-pks-cluster: k8s-cluster-info  temp/pks/create-cluster.sh ./pci/k8s/config
	temp/pks/create-cluster.sh $(K8S_CLUSTER) small

delete-gke-cluster:	temp/gke/delete-cluster.sh
	temp/gke/delete-cluster.sh $(K8S_CLUSTER)
	rm -rf ./pci
	rm -rf ./mygcloud

delete-pks-cluster:	temp/pks/delete-cluster.sh
	temp/pks/delete-cluster.sh $(K8S_CLUSTER)
	rm -rf ./pci

run-pks:	build create-pks-cluster run delete-pks-cluster

run-gke:	build create-gke-cluster run delete-gke-cluster

run: build clustername k8s-cluster-info
	docker run \
	-e K8S_CLUSTER \
	-e KUBECONFIG=/pci/k8s/config \
	-v `pwd`/pci:/pci \
	cfplatformeng/$(IMAGE_NAME):latest

gcb-pks: build clustername publish k8s-cluster-info
	gcloud builds submit --config gcb-config.yaml \
	--substitutions _K8S_CLUSTER=${K8S_CLUSTER}

gcb-gke: build clustername publish k8s-cluster-info
	gcloud builds submit --config gcb-config.yaml \
	--substitutions _K8S_CLUSTER=${K8S_CLUSTER}

# TODO use volume mounts for live editing
shell: build clustername
	docker run \
	-e K8S_CLUSTER \
	-e KUBECONFIG=/pci/k8s/config \
	-v `pwd`/pci:/pci \
	-it cfplatformeng/$(IMAGE_NAME):latest /bin/bash

lint: test/commands.sh
	echo $? | xargs shellcheck