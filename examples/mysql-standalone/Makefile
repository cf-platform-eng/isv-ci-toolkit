OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
SHELL = /bin/bash

default: build

.PHONY: build
.PHONY: publish
.PHONY: run
.PHONY: shell
.PHONY: clustername
.PHONY: lint

TEST_FILES = $(shell find ./test -name "*")
#TEST_SHELL_FILES = $(shell find ./test -name "*.sh" )
TEMP_FILES = $(shell find ./temp -name "*" | grep -v "/phony/" )

temp/phony/cfplatformeng:
	mkdir -p temp/phony/cfplatformeng

temp/phony/cfplatformeng/test-mysql-standalone: temp/phony/cfplatformeng Dockerfile $(TEST_FILES) $(TEMP_FILES)
	docker build . -t cfplatformeng/test-mysql-standalone
	touch temp/phony/cfplatformeng/test-mysql-standalone

temp/configkube: ../../configkube/configkube
	cp ../../configkube/configkube temp/configkube

temp/kubecfg: ../../configkube/kubecfg
	cp ../../configkube/kubecfg temp/kubecfg

build: lint temp/configkube temp/phony/cfplatformeng/test-mysql-standalone

publish:
#	echo "PKS licensing is blocking this"
	docker push cfplatformeng/test-mysql-standalone

clustername:
	echo "Cluster Name is: ${CLUSTER_NAME}"

k8s-cluster-info:
	if [ -z "${K8S_CLUSTER}" ] ; then echo "K8S_CLUSTER must be specified"; exit 1; fi


run: build temp/kubecfg clustername k8s-cluster-info
	source temp/kubecfg && docker run \
	-e K8S_CLUSTER \
	-e K8S_SERVER \
	-e K8S_SERVER_CA \
	-e K8S_USER_TOKEN \
	cfplatformeng/test-mysql-standalone:latest

gcb: build temp/kubecfg clustername publish k8s-cluster-info
	source temp/kubecfg && gcloud builds submit --config gcb-config.yaml \
	--substitutions _K8S_CLUSTER=${K8S_CLUSTER},_K8S_SERVER=${K8S_SERVER},_K8S_SERVER_CA=${K8S_SERVER_CA},_K8S_USER_TOKEN=${K8S_USER_TOKEN}

# TODO use volume mounts for live editing
shell: build temp/kubecfg clustername
	source temp/kubecfg && docker run \
	-e K8S_CLUSTER \
	-e K8S_SERVER \
	-e K8S_SERVER_CA \
	-e K8S_USER_TOKEN \
	-it cfplatformeng/test-mysql-standalone:latest /bin/bash

lint: test/commands.sh
	echo $? | xargs shellcheck