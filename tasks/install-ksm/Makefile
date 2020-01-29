SHELL=/bin/bash

DOCKER_REPO := cfplatformeng
IMAGE_NAME := install-ksm
BASH_SRC := $(shell find . -name "*.sh")
SRC := $(BASH_SRC) needs.json Dockerfile

pks-environment-path:
ifndef PKS_ENVIRONMENT_PATH
	$(error PKS_ENVIRONMENT_PATH not defined. Set this with the full path to your PKS env.json from Toolsmiths)
endif
	$(NOOP)

pas-environment-path:
ifndef PAS_ENVIRONMENT_PATH
	$(error PAS_ENVIRONMENT_PATH not defined. Set this with the full path to your PAS env.json from Toolsmiths)
endif
	$(NOOP)

runtime-deps: pas-environment-path pks-environment-path

.PHONY: clean
clean:
	rm -rf temp
	rm -rf logs
	rm -rf build
	docker image rm -f $(IMAGE_NAME)

temp/make-tags/build: $(SRC)
	docker build . --pull --tag $(IMAGE_NAME)
	mkdir -p temp/make-tags && touch temp/make-tags/build

temp/make-tags/interactive-build: Dockerfile
	docker build . --pull --tag $(IMAGE_NAME)
	mkdir -p temp/make-tags && touch temp/make-tags/interactive-build

.PHONY: build
build: temp/make-tags/build

.PHONY: publish
publish: build
	docker tag $(IMAGE_NAME) $(DOCKER_REPO)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

.PHONY: logs
logs:
	mkdir -p ./logs

.PHONY: run
run: runtime-deps logs temp/make-tags/build
	set -o pipefail; docker run \
	-e PIVNET_TOKEN \
	-e STORAGE_SERVICE_ACCOUNT_KEY \
	-e TEARDOWN \
	-v ${PKS_ENVIRONMENT_PATH}:/input/pks-environment.json \
	-v ${PAS_ENVIRONMENT_PATH}:/input/pas-environment.json \
	$(IMAGE_NAME) run 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

.PHONY: shell
shell: temp/make-tags/interactive-build
	docker run -it \
	-e PIVNET_TOKEN \
	-e STORAGE_SERVICE_ACCOUNT_KEY \
	-e TEARDOWN \
	-v ${PKS_ENVIRONMENT_PATH}:/input/pks-environment.json \
	-v ${PAS_ENVIRONMENT_PATH}:/input/pas-environment.json \
	-v ${PWD}:/job \
	$(IMAGE_NAME) \
	shell
