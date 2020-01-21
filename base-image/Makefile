SHELL = /bin/bash

default: test

.PHONY: clean
clean:
	rm -rf temp

#
# Docker image targets
#
temp/make-tags/build: Dockerfile jeb.sh
	@docker build . --file Dockerfile --tag cfplatformeng/base-image:local
	mkdir -p temp/make-tags && touch temp/make-tags/build

.PHONY: build
build: temp/make-tags/build

.PHONY: publish
publish: build
	docker push cfplatformeng/base-image:latest

.PHONY: shell
shell: build
	docker run -it --rm -v ${PWD}:/root cfplatformeng/base-image:local shell

.PHONY: test
test: 
	go mod download
	ginkgo -r .