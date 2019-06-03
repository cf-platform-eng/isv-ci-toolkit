.PHONY: build clean run gcb publish lint

clean:
	rm -rf temp

lint: check.sh test.sh
	shellcheck check.sh test.sh

temp/phony/ops-manifest-static-test: Dockerfile check.sh test.sh
	docker build . --tag gcr.io/fe-rabbit-mq-tile-ci/ops-manifest-static-test:latest
	mkdir -p temp/phony && touch temp/phony/ops-manifest-static-test

build: lint temp/phony/ops-manifest-static-test

publish: build
	echo "WARNING: this image contains files that are not fit for public release.  DO NOT PUBLISH PUBLICLY"
	docker push gcr.io/fe-rabbit-mq-tile-ci/ops-manifest-static-test:latest

TILE_PATH ?= $(shell ls input/*.pivotal)
TILE_NAME = $(shell basename $(TILE_PATH))
CONFIG_FILE_PATH ?= $(shell ls input/*.json)
CONFIG_FILE_NAME = $(shell basename $(CONFIG_FILE_PATH))
variables:
	$(info Using tile: $(TILE_PATH))
	$(info Uisng config file: $(CONFIG_FILE_PATH))

run: variables build
	docker run -it \
		-v `pwd`/input:/input \
		-e TILE_PATH=$(TILE_PATH) \
		-e CONFIG_FILE_PATH=$(CONFIG_FILE_PATH) \
		gcr.io/fe-rabbit-mq-tile-ci/ops-manifest-static-test:latest

gcb: variables publish
	gsutil cp $(TILE_PATH) gs://isv-ci-staging/input/$(TILE_NAME) && \
		gsutil cp $(CONFIG_FILE_PATH) gs://isv-ci-staging/input/$(CONFIG_FILE_NAME) && \
		gcloud builds submit --config gcb-config.yaml \
			--substitutions _TILE_NAME="$(TILE_NAME)",_CONFIG_FILE_NAME="${CONFIG_FILE_NAME}"

shell: variables build
	docker run -it \
		-v `pwd`/input:/input \
		-e TILE_PATH=$(TILE_PATH) \
		-e CONFIG_FILE_PATH=$(CONFIG_FILE_PATH) \
		gcr.io/fe-rabbit-mq-tile-ci/ops-manifest-static-test:latest /bin/bash
