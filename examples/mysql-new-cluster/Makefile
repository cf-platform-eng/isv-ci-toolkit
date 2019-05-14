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

gcp-creds:
	if [ -z "${GCP_CREDS_FILE}" ] ; then echo "GCP_CREDS_FILE must be specified"; exit 1; fi

temp/gke/create-cluster.sh:	../gke-clusters/create-cluster.sh
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
	-v $(shell pwd)/pci:/pci \
	-e CLOUDSDK_CONFIG=/config/mygcloud \
	-v $(shell pwd)/mygcloud:/config/mygcloud \
	-v $(shell dirname "${GCP_CREDS_FILE}"):/tmp/certs \
	cfplatformeng/$(IMAGE_NAME):latest

gcb-pks: build clustername publish k8s-cluster-info gcp-creds
	gsutil cp ${GCP_CREDS_FILE} gs://isv-ci-staging && \
	gcloud builds submit --config gcb-config-pks.yaml --timeout=1800 \
	--substitutions _K8S_CLUSTER=${K8S_CLUSTER},_PKS_API=${PKS_API},_PKS_USER_NAME=${PKS_USER_NAME},_PKS_PASSWORD=${PKS_PASSWORD},_GCP_CREDS_FILENAME=$(shell basename "${GCP_CREDS_FILE}")

gcb-gke: build clustername publish k8s-cluster-info
	gcloud builds submit --config gcb-config-gke.yaml \
	--substitutions _K8S_CLUSTER=${K8S_CLUSTER}

# TODO use volume mounts for live editing
shell: build clustername
	docker run \
	-e K8S_CLUSTER \
	-e KUBECONFIG=/pci/k8s/config \
	-v `pwd`/pci:/pci \
	-e CLOUDSDK_CONFIG=/config/mygcloud \
	-v $(pwd)/mygcloud:/config/mygcloud \
	-v `dirname "${GCP_CREDS_FILE}"`:/tmp/certs \
	-it cfplatformeng/$(IMAGE_NAME):latest /bin/bash

lint: test/commands.sh
	echo $? | xargs shellcheck