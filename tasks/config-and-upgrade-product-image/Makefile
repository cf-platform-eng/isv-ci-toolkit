.PHONY: build run shell lint test

SKIP_APPLY_CHANGES ?= false
SKIP_TILE_UPLOAD ?= false

build: lint
	docker build . --tag cfplatformeng/config-and-upgrade-product-image:latest

run: build
	docker run \
		-e STARTING_PCF_VERSION \
		-e UPGRADED_PCF_VERSION \
		-e PRODUCT_VERSION \
		-e UPGRADED_PRODUCT_VERSION \
		-e PRODUCT_NAME \
		-e SKIP_APPLY_CHANGES=$(SKIP_APPLY_CHANGES) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		cfplatformeng/config-and-upgrade-product-image:latest

shell: build
	docker run -it \
		-e STARTING_PCF_VERSION \
		-e UPGRADED_PCF_VERSION \
		-e PRODUCT_VERSION \
		-e UPGRADED_PRODUCT_VERSION \
		-e PRODUCT_NAME \
		-e SKIP_APPLY_CHANGES=$(SKIP_APPLY_CHANGES) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		cfplatformeng/config-and-upgrade-product-image:latest \
		bash

lint:
	shellcheck *.sh

test: lint
	bats --tap *.bats
