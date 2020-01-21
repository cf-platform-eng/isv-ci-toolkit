SHELL = /bin/bash

default: test

GO-VER = go1.13

# #### GO Binary Management ####
.PHONY: deps-go-binary
deps-go-binary:
	echo "Expect: $(GO-VER)" && \
		echo "Actual: $$(go version)" && \
	 	go version | grep $(GO-VER) > /dev/null

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
test: deps-go-binary
	go mod download
	ginkgo -r .