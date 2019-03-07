SHELL = /bin/bash
default: build

build:
	export GOARCH=amd64
	export GOOS=linux
	$(MAKE) --directory ../tileinspect build
	cp ../tileinspect/build/tileinspect artifacts

	$(MAKE) --directory ../marman build
	cp ../marman/build/marman artifacts

	docker build . -t cfplatformeng/test-tile-test
