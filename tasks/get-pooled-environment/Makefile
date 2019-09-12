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
	docker build --build-arg GITHUB_TOKEN=${GITHUB_TOKEN} --pull . -t cfplatformeng/get-pooled-environment

# publish:
# 	docker push cfplatformeng/get-pooled-environment

run:
	docker run -it \
		-e POOL_TYPE \
		-e TOOLSMITHS_API_TOKEN \
		-v `pwd`/output:/output \
		cfplatformeng/get-pooled-environment:latest

shell:
	docker run -it \
		-e POOL_TYPE \
		-e TOOLSMITHS_API_TOKEN \
		-v `pwd`/output:/output \
		cfplatformeng/get-pooled-environment:latest \
		/bin/bash
