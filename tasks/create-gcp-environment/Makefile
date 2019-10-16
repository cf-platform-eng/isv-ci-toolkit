.PHONY: build clean deps lint publish run shell test

temp/make-tags/deps:
	mkdir -p temp/make-tags
	touch temp/make-tags/deps
	curl https://raw.githubusercontent.com/grayhemp/bats-mock/master/src/bats-mock.bash > temp/bats-mock.bash

clean:
	rm -f temp/make-tags/deps

deps: temp/make-tags/deps

lint:
	shellcheck *.sh

test: deps lint
	bats --tap *.bats

build:
	docker build --pull . -t cfplatformeng/create-gcp-environment

publish:
	docker push cfplatformeng/create-gcp-environment

run:
	docker run -it \
		-e OPS_MAN_VERSION \
		-e OPTIONAL_OPS_MAN_VERSION \
		-e PARENT_ZONE \
		-e PIVNET_TOKEN \
		-e DNS_SUFFIX \
		-e PAVER \
		-e CRED_FILE=$(shell basename "${CRED_FILE_PATH}") \
		-e GIPS_ADDRESS \
		-e GIPS_UAA_ADDRESS \
		-v $(shell dirname "${CRED_FILE_PATH}"):/input \
		-v `pwd`/output:/output \
		cfplatformeng/create-gcp-environment:latest

shell:
	docker run -it \
		-e OPS_MAN_VERSION \
		-e OPTIONAL_OPS_MAN_VERSION \
		-e PARENT_ZONE \
		-e PIVNET_TOKEN \
		-e DNS_SUFFIX \
		-e PAVER \
		-e CRED_FILE=$(shell basename "${CRED_FILE_PATH}") \
		-e GIPS_ADDRESS \
		-e GIPS_UAA_ADDRESS \
		-v $(shell dirname "${CRED_FILE_PATH}"):/input \
		-v `pwd`/output:/output \
		cfplatformeng/create-gcp-environment:latest \
		/bin/bash
