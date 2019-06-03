PRODUCT_VERSION ?= 1.4.0
PRODUCT_NAME ?= pks
PCF_VERSION ?= 2.5.2
SKIP_TILE_UPLOAD ?= false

temp/marman:
	mkdir -p temp
	(cd temp && marman download-release -o cf-platform-eng -r marman -f "marman-linux")
	mv temp/marman-linux temp/marman

build: temp/marman
	docker build . --tag gcr.io/fe-rabbit-mq-tile-ci/config-pks-image:latest

run:
	docker run \
		-e PRODUCT_VERSION=$(PRODUCT_VERSION) \
		-e PRODUCT_NAME=$(PRODUCT_NAME) \
		-e PCF_VERSION=$(PCF_VERSION) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		gcr.io/fe-rabbit-mq-tile-ci/config-pks-image:latest

shell:
	docker run -it \
		-e PRODUCT_VERSION=$(PRODUCT_VERSION) \
		-e PRODUCT_NAME=$(PRODUCT_NAME) \
		-e PCF_VERSION=$(PCF_VERSION) \
		-e SKIP_TILE_UPLOAD=$(SKIP_TILE_UPLOAD) \
		-v `pwd`/input:/input \
		gcr.io/fe-rabbit-mq-tile-ci/config-pks-image:latest \
		bash

lint:
	shellcheck *.sh
