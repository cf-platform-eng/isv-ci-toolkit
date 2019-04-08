OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
SHELL = /bin/bash
SPANSHOT_NAME = ./temp/snapshots/$(shell date +"%Y-%m-%d-%H-%M-%S").snap

default: build

.PHONY: build
.PHONY: run
.PHONY: shell
.PHONY: clustername
.PHONY: lint

snapshot:
	mkdir -p ./temp/snapshots
	kubectl get namespaces -o=custom-columns=KIND:.kind,NAME:.metadata.name > "$(SPANSHOT_NAME)" 2>&1
	kubectl get all --all-namespaces -o=custom-columns=KIND:.kind,NAME:.metadata.name,NS:.metadata.namespace >> "$(SPANSHOT_NAME)" 2>&1

diff:
	ls -d1 temp/snapshots/* | sort --reverse | head -2 | xargs diff -w

TEST_FILES = $(shell find ./test -name "*")
TEMP_FILES = $(shell find ./temp -name "*" | grep -v "/phony/" )

temp/phony/cfplatformeng:
	mkdir -p temp/phony/cfplatformeng

temp/phony/cfplatformeng/test-nsie: temp/phony/cfplatformeng Dockerfile $(TEST_FILES) $(TEMP_FILES)
	docker build . --tag gcr.io/fe-rabbit-mq-tile-ci/nsie-kls-test:latest
	touch temp/phony/cfplatformeng/test-nsie

build: lint temp/phony/cfplatformeng/test-nsie

publish: build
	echo "WARNING: this image contains files that are not fit for public release.  DO NOT PUBLISH PUBLICLY"

	docker push gcr.io/fe-rabbit-mq-tile-ci/nsie-kls-test:latest

clustername:
	if [ -z "${CLUSTER_NAME}" ] ; then echo "CLUSTER_NAME must be specified"; exit 1; fi
	echo "Cluster Name is: ${CLUSTER_NAME}"

pks-password:
	if [ -z "${PKS_PASSWORD}" ] ; then echo "PKS_PASSWORD must be specified"; exit 1; fi

chart-present:
	if [ `ls -1 input/chart | wc -l` -ne 1 ] ; then echo "There must be a single chart (<filename>.tgz) inside input/chart"; exit 1; fi

run: build clustername pks-password chart-present
 	# Not sure if using '-v' is the ultimate solution for automated builds
	docker run -it \
		-v `pwd`/input:/input \
		-e CHART_DIRECTORY="/input/chart" \
		-e CLUSTER_NAME \
		-e PKS_API_ENDPOINT=`cat ${HOME}/.pks/creds.yml | yq -r .api` \
		-e PKS_USERNAME=`cat ${HOME}/.pks/creds.yml | yq -r .username` \
		-e PKS_PASSWORD \
		gcr.io/fe-rabbit-mq-tile-ci/nsie-kls-test:latest

gcb: publish clustername pks-password chart-present
	gsutil cp input/chart/*.tgz gs://isv-ci-staging && \
		gcloud builds submit --config gcb-config.yaml \
			--substitutions _CHART_NAME=`basename input/chart/*.tgz`,_CLUSTER_NAME="${CLUSTER_NAME}",_PKS_API_ENDPOINT=`cat ${HOME}/.pks/creds.yml | yq -r .api`,_PKS_USERNAME=`cat ${HOME}/.pks/creds.yml | yq -r .username`,_PKS_PASSWORD="${PKS_PASSWORD}"

shell: build clustername pks-password chart-present
	PKS_CREDS_FILE=`cat ${HOME}/.pks/creds.yml` \
		docker run -it \
		-v `pwd`/input:/input \
		-e CHART_DIRECTORY="/input/chart" \
		-e CLUSTER_NAME \
		-e PKS_API_ENDPOINT=`cat ${HOME}/.pks/creds.yml | yq -r .api` \
		-e PKS_USERNAME=`cat ${HOME}/.pks/creds.yml | yq -r .username` \
		-e PKS_PASSWORD \
		gcr.io/fe-rabbit-mq-tile-ci/nsie-kls-test:latest /bin/bash

lint: test/commands.sh test/validator.sh
	echo $? | xargs shellcheck