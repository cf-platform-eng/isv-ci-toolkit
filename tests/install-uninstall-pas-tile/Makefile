.PHONY: tile-path tile-config-path tile-config

SRC := $(shell find . -name "*.sh") needs.json Dockerfile

DOCKER_REPO := cfplatformeng
IMAGE_NAME := tile-install-uninstall

temp/make-tags/build: $(SRC)
	docker build . --pull --tag $(IMAGE_NAME)
	mkdir -p temp/make-tags && touch temp/make-tags/build

temp/make-tags/interactive-build: Dockerfile
	docker build . --pull --tag $(IMAGE_NAME)
	mkdir -p temp/make-tags && touch temp/make-tags/interactive-build

build: temp/make-tags/build

clean:
	rm -rf ./temp
	rm -rf ./logs
	docker image rm -f $(IMAGE_NAME)

logs:
	mkdir -p ./logs

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

runtime-deps: tile-path tile-config-path

publish: build
	docker tag $(IMAGE_NAME) $(DOCKER_REPO)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

run: runtime-deps build logs
	docker run \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e OM_SKIP_SSL_VALIDATION \
	-e PIVNET_TOKEN \
	-e USE_FULL_DEPLOY \
	-v ${TILE_PATH}:/input/tile.pivotal \
	-v ${TILE_CONFIG_PATH}:/input/config.json \
	$(IMAGE_NAME) run 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

shell: temp/make-tags/interactive-build
	docker run -it \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e OM_SKIP_SSL_VALIDATION \
	-e PIVNET_TOKEN \
	-e USE_FULL_DEPLOY \
	-v ${TILE_PATH}:/input/tile.pivotal \
	-v ${TILE_CONFIG_PATH}:/input/config.json \
	-v ${PWD}:/job \
	$(IMAGE_NAME) \
	shell
