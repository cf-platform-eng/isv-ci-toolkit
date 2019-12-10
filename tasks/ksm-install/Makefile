SHELL=/bin/bash

.PHONY: deps-test clean lint test build publish run shell needs-list needs-check

IMAGE_NAME := "ksm-install"
BASH_SRC := $(shell find . -name "*.sh")
SRC := $(BASH_SRC) needs.json Dockerfile
TEST_SRC := $(shell find . -name "*.bats")
# DOCKER_REPO := <fill in your DOCKER_REPO>


temp/test-helpers.bash:
	mkdir -p temp
	# TODO: this does not feel right.. (but it should be versioned)
	curl https://raw.githubusercontent.com/cf-platform-eng/isv-ci-toolkit/6c2663a08b20849a1047b6834a8feaa20e2e728f/tools/test-helpers.bash > temp/test-helpers.bash

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

clean:
	rm -rf temp
	docker image rm -f $(IMAGE_NAME)
	rm -rf ./logs

temp/make-tags/lint: $(BASH_SRC)
	shellcheck *.sh
	mkdir -p temp/make-tags && touch temp/make-tags/lint

lint: temp/make-tags/lint

temp/make-tags/test: temp/bats-mock.bash temp/test-helpers.bash $(BASH_SRC) $(TEST_SRC)
	bats --tap *.bats
	mkdir -p temp/make-tags && touch temp/make-tags/test

test: deps-test temp/make-tags/lint temp/make-tags/test

temp/make-tags/build: $(SRC)
	docker build . --pull --tag $(IMAGE_NAME)
	mkdir -p temp/make-tags && touch temp/make-tags/build

build: temp/make-tags/build

publish: build
ifndef DOCKER_REPO
	$(error "Please define DOCKER_REPO location to publish image")
endif
	docker tag $(IMAGE_NAME) $(DOCKER_REPO)/$(IMAGE_NAME):latest
	docker push $(DOCKER_REPO)/$(IMAGE_NAME):latest

run-deps: build

logs:
	mkdir -p ./logs

run: run-deps logs temp/make-tags/build
	set -o pipefail; docker run \
	-e KUBECONFIG \
	-v ${KUBECONFIG}:/input/kubeconfig \
	$(IMAGE_NAME) 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

define run-docker-interactive
	docker run -it \
	-e KUBECONFIG \
	-v ${KUBECONFIG}:/input/kubeconfig \
	-v ${PWD}:/test \
	$(IMAGE_NAME) \
	$1 $2
endef

shell: temp/make-tags/build
	$(call run-docker-interactive,"/bin/bash")

needs-list:
	$(call run-docker-interactive,/bin/bash,-c "needs list")

needs-check:
	$(call run-docker-interactive,/bin/bash,-c "needs check")
