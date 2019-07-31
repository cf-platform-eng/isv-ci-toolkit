.PHONY: build clean deps lint publish run shell test

temp/make-tags/deps:
	mkdir -p temp/make-tags
	touch temp/make-tags/deps
	curl https://raw.githubusercontent.com/cf-platform-eng/bats-mock/master/src/bats-mock.bash > temp/bats-mock.bash

clean:
	rm -f temp/make-tags/deps

deps: temp/make-tags/deps

lint:
	shellcheck *.sh

test: deps lint
	bats --tap *.bats

build:
	docker build . -t gcr.io/fe-rabbit-mq-tile-ci/teardown-environment

publish:
	docker push gcr.io/fe-rabbit-mq-tile-ci/teardown-environment

run:
	docker run -it \
		-e INSTALLATION_NAME \
		-e CRED_FILE=$(shell basename "${CRED_FILE_PATH}") \
		-e GIPS_ADDRESS \
		-e GIPS_UAA_ADDRESS \
		-v $(shell dirname "${CRED_FILE_PATH}"):/input \
		gcr.io/fe-rabbit-mq-tile-ci/teardown-environment

shell:
	docker run -it \
		-e INSTALLATION_NAME \
		-e CRED_FILE=$(shell basename "${CRED_FILE_PATH}") \
		-e GIPS_ADDRESS \
		-e GIPS_UAA_ADDRESS \
		-v $(shell dirname "${CRED_FILE_PATH}"):/input \
		gcr.io/fe-rabbit-mq-tile-ci/teardown \
		/bin/bash
