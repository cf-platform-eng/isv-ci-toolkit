SHELL=/bin/bash

.PHONY: clean build publish run shell needs-list needs-check lint deps-test

DOCKER_REPO := cfplatformeng
IMAGE_NAME := install-ksm
BASH_SRC := $(shell find . -name "*.sh")
SRC := $(BASH_SRC) needs.json Dockerfile
TEST_SRC := $(shell find . -name "*.bats")

SHELLCHECK_INSTALLED := $(shell command -v shellcheck 2>&1 > /dev/null; echo $$?)

deps-test:
ifneq ($(SHELLCHECK_INSTALLED),0)
  $(warning 'shellcheck' not installed. See https://www.shellcheck.net/)
  $(error "Please install missing dependencies")
endif

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

build: temp/make-tags/build

publish: build
	docker tag $(IMAGE_NAME) $(DOCKER_REPO)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

run-deps: build

logs:
	mkdir -p ./logs

run: run-deps logs temp/make-tags/build
	set -o pipefail; docker run \
	-v ${PWD}/input:/input \
	$(IMAGE_NAME) 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

define run-docker-interactive
	docker run -it \
	-v ${PWD}/input:/input \
	-v ${PWD}:/task \
	$(IMAGE_NAME) \
	$1 $2
endef

shell: temp/make-tags/interactive-build
	$(call run-docker-interactive,"/bin/bash")

needs-list: temp/make-tags/interactive-build
	$(call run-docker-interactive,/bin/bash,-c "needs list")

needs-check: temp/make-tags/interactive-build
	$(call run-docker-interactive,/bin/bash,-c "needs check")
