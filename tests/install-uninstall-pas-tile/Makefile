.PHONY: pas-config om-username om-password om-target tile-config
.PHONY: tile-path tile-config-path clean build run run-deps shell deps-test test lint

BASH_SRC := $(shell find scripts -name "*.sh")
SRC := $(BASH_SRC) needs.json Dockerfile
TEST_SRC := $(shell find scripts -name "*.bats")

BATS_INSTALLED := $(shell command -v bats 2>&1 > /dev/null; echo $$?)
SHELLCHECK_INSTALLED := $(shell command -v shellcheck 2>&1 > /dev/null; echo $$?)

deps-test:
ifneq ($(BATS_INSTALLED),0)
  $(warning 'bats' not installed. See https://github.com/bats-core/bats-core)
  MISSING := 1
endif
ifneq ($(SHELLCHECK_INSTALLED),0)
  $(warning 'shellcheck' not installed. See https://www.shellcheck.net/)
  MISSING := 1
endif
ifdef MISSING
  $(error "Please install missing dependencies")
endif

om-username:
ifndef OM_USERNAME
	$(error OM_USERNAME not defined)
else
	$(NOOP)
endif

om-password:
ifndef OM_PASSWORD
	$(error OM_PASSWORD not defined)
else
	$(NOOP)
endif

om-target:
ifndef OM_TARGET
	$(error OM_TARGET not defined)
else
	$(NOOP)
endif

pas-config:	om-username om-password om-target

tile-path:
ifndef TILE_PATH
	$(error TILE_PATH not defined. Set this with the full path to your .pivotal tile)
else
	$(NOOP)
endif

tile-config-path:
ifndef TILE_CONFIG_PATH
	$(error TILE_CONFIG_PATH not defined)
else
	$(NOOP)
endif

tile-config: tile-path tile-config-path

pivnet-token:
ifndef PIVNET_TOKEN
	$(error PIVNET_TOKEN not defined, please obtain an api token from your Pivotal Network profile)
else
	$(NOOP)
endif

clean:
	rm -rf temp
	docker image rm -f cfplatformeng/install-uninstall-test-image
	rm -rf ./logs

temp/make-tags/lint: $(BASH_SRC)
	shellcheck scripts/*.sh
	mkdir -p temp/make-tags && touch temp/make-tags/lint

lint: temp/make-tags/lint

temp/make-tags/test: $(BASH_SRC) $(TEST_SRC)
	bats --tap scripts/*.bats
	mkdir -p temp/make-tags && touch temp/make-tags/test

test: deps-test temp/make-tags/lint temp/make-tags/test

temp/make-tags/build: temp/make-tags/lint temp/make-tags/test $(SRC)
	docker build . --tag cfplatformeng/install-uninstall-test-image --no-cache --pull
	mkdir -p temp/make-tags && touch temp/make-tags/build

build: temp/make-tags/build

run-deps: pivnet-token pas-config tile-config build

logs:
	mkdir -p ./logs

run: run-deps logs temp/make-tags/build
	docker run \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e OM_SKIP_SSL_VALIDATION \
	-e PIVNET_TOKEN \
	-e TILE_NAME=$(shell basename "${TILE_PATH}") \
	-e TILE_CONFIG=$(shell basename "${TILE_CONFIG_PATH}") \
	-e USE_SELECTIVE_DEPLOY \
	-v $(shell dirname "${TILE_PATH}"):/tile \
	-v $(shell dirname "${TILE_CONFIG_PATH}"):/tile-config \
	-v ${PWD}/../../tools:/bin/tools \
	cfplatformeng/install-uninstall-test-image 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

shell: run-deps temp/make-tags/build
	docker run -it \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e OM_SKIP_SSL_VALIDATION \
	-e PIVNET_TOKEN \
	-e TILE_NAME=$(shell basename "${TILE_PATH}") \
	-e TILE_CONFIG=$(shell basename "${TILE_CONFIG_PATH}") \
	-e USE_SELECTIVE_DEPLOY \
	-v $(shell dirname "${TILE_PATH}"):/tile \
	-v $(shell dirname "${TILE_CONFIG_PATH}"):/tile-config \
	-v ${PWD}/../../tools:/bin/tools \
	cfplatformeng/install-uninstall-test-image \
	/bin/bash

