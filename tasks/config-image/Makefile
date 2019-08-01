.PHONY: pcf-version product-version product-name build run shell lint test

SKIP_APPLY_CHANGES ?= false
SKIP_TILE_UPLOAD ?= false

pcf-version:
ifndef PCF_VERSION
	$(error PCF_VERSION not defined)
else
	$(NOOP)
endif

product-version:
ifndef PRODUCT_VERSION
	$(error PRODUCT_VERSION not defined)
else
	$(NOOP)
endif

product-name:
ifndef PRODUCT_NAME
	$(error PRODUCT_NAME not defined)
else
	$(NOOP)
endif

build: lint test
	docker build . --tag gcr.io/fe-rabbit-mq-tile-ci/config-image:latest

run: pcf-version product-version product-name build
	docker run \
		-e PCF_VERSION \
		-e PRODUCT_VERSION \
		-e PRODUCT_NAME \
		-e SKIP_APPLY_CHANGES=$(SKIP_APPLY_CHANGES) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		gcr.io/fe-rabbit-mq-tile-ci/config-image:latest

shell: pcf-version product-version product-name build
	docker run -it \
		-e PCF_VERSION \
		-e PRODUCT_VERSION \
		-e PRODUCT_NAME \
		-e SKIP_APPLY_CHANGES=$(SKIP_APPLY_CHANGES) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		gcr.io/fe-rabbit-mq-tile-ci/config-image:latest \
		bash

lint:
	shellcheck *.sh

test:
	bats --tap *.bats
