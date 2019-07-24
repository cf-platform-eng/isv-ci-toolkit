.PHONY: pas-config om-username om-password om-target tile-config tile-path tile-config-path clean build run run-deps shell

pas-config:	om-username om-password om-target
tile-config: tile-path tile-config-path

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

pivnet-token:
ifndef PIVNET_TOKEN
	$(error PIVNET_TOKEN not defined, please obtain an api token from your Pivotal Network profile)
else
	$(NOOP)
endif

clean:
	docker image rm install-uninstall-test-image
	rm -rf ./logs

build: test
	docker build . --tag install-uninstall-test-image --no-cache --pull

run-deps: pivnet-token pas-config tile-config build

logs:
	mkdir -p ./logs

run: run-deps logs
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
	install-uninstall-test-image:latest | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

shell: run-deps
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
	install-uninstall-test-image:latest \
	/bin/bash

lint:
	shellcheck scripts/*.sh

test: lint
	bats --tap scripts/*.bats

