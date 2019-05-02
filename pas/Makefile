SHELL = /bin/bash

default: build

.PHONY: build
.PHONY: publish
.PHONY: lint

#
# Depdendency targets
#
PKSCTL_VERSION ?= 0.0.502
temp/pksctl:	 runnable
	mkdir -p temp
	./scripts/fetch-pksctl.sh $(PKSCTL_VERSION) temp/pksctl

build:	temp/pksctl
	docker build . -t cfplatformeng/toolkit-pas

publish:
	docker push cfplatformeng/toolkit-pas

lint:
	shellcheck scripts/*.sh

runnable:
	if [ -z "${ENV_IS_SET}" ]; then echo "Did you SetEnv?"; exit 1; fi
