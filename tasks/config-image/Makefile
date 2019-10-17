.PHONY: build run shell lint test

SKIP_APPLY_CHANGES ?= false
SKIP_TILE_UPLOAD ?= false

build: lint test
	docker build . --tag cfplatformeng/config-image:latest

run: build
	docker run \
		-e PCF_VERSION \
		-e PIVNET_TOKEN \
		-e PRODUCT_VERSION \
		-e PRODUCT_NAME \
		-e SKIP_APPLY_CHANGES=$(SKIP_APPLY_CHANGES) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		cfplatformeng/config-image:latest

shell: build
	docker run -it \
		-e PCF_VERSION \
		-e PIVNET_TOKEN \
		-e PRODUCT_VERSION \
		-e PRODUCT_NAME \
		-e SKIP_APPLY_CHANGES=$(SKIP_APPLY_CHANGES) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		cfplatformeng/config-image:latest \
		bash

lint:
	shellcheck --external-sources *.sh

test: lint
