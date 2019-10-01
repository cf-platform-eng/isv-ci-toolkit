.PHONY: pas-config om-username om-password om-target tile-config
.PHONY: tile-path tile-config-path clean build run run-deps shell deps-test test lint

BASH_SRC := $(shell find . -name "*.sh")
SRC := $(BASH_SRC) needs.json Dockerfile
TEST_SRC := $(shell find . -name "*.bats")

temp/bats-mock.bash:
	mkdir -p temp
	curl https://raw.githubusercontent.com/cf-platform-eng/bats-mock/master/src/bats-mock.bash > temp/bats-mock.bash

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

clean:
	rm -rf temp
	docker image rm -f cfplatformeng/install-uninstall-test-image
	rm -rf ./logs

temp/make-tags/lint: $(BASH_SRC)
	shellcheck *.sh
	mkdir -p temp/make-tags && touch temp/make-tags/lint

lint: temp/make-tags/lint

temp/make-tags/test: temp/bats-mock.bash $(BASH_SRC) $(TEST_SRC)
	bats --tap *.bats
	mkdir -p temp/make-tags && touch temp/make-tags/test

test: deps-test temp/make-tags/lint temp/make-tags/test

temp/make-tags/build: temp/make-tags/lint temp/make-tags/test $(SRC)
	docker build . --tag cfplatformeng/install-uninstall-test-image
	mkdir -p temp/make-tags && touch temp/make-tags/build

build: temp/make-tags/build

run-deps: tile-config build

logs:
	mkdir -p ./logs

run: run-deps logs temp/make-tags/build
	docker run \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e OM_SKIP_SSL_VALIDATION \
	-e PIVNET_TOKEN \
	-e TILE_PATH=/input/$(shell basename "${TILE_PATH}") \
	-e TILE_CONFIG_PATH=/input/$(shell basename "${TILE_CONFIG_PATH}") \
	-e USE_FULL_DEPLOY \
	-v ${TILE_PATH}:/input/$(shell basename "${TILE_PATH}") \
	-v ${TILE_CONFIG_PATH}:/input/$(shell basename "${TILE_CONFIG_PATH}") \
	-v ${PWD}/../../tools:/bin/tools \
	cfplatformeng/install-uninstall-test-image 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

define run-docker-interactive
	docker run -it \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e OM_SKIP_SSL_VALIDATION \
	-e PIVNET_TOKEN \
	-e TILE_PATH=/input/$(shell basename "${TILE_PATH}") \
	-e TILE_CONFIG_PATH=/input/$(shell basename "${TILE_CONFIG_PATH}") \
	-e USE_FULL_DEPLOY \
	-v ${TILE_PATH}:/input/$(shell basename "${TILE_PATH}") \
	-v ${TILE_CONFIG_PATH}:/input/$(shell basename "${TILE_CONFIG_PATH}") \
	-v ${PWD}/../../tools:/bin/tools \
	-v ${PWD}:/test \
	cfplatformeng/install-uninstall-test-image \
	$1 $2
endef

shell: tile-config temp/make-tags/build
	$(call run-docker-interactive,"/bin/bash")

needs-list: tile-config
	$(call run-docker-interactive,/bin/bash,-c "needs list")

needs-check: tile-config
	$(call run-docker-interactive,/bin/bash,-c "needs check")
