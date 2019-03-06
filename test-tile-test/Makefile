SHELL = /bin/bash
default: build

build:
	GOARCH=amd64 GOOS=linux $(MAKE) --directory ../tileinspect build
	cp ../tileinspect/build/tileinspect artifacts
	docker build . -t cfplatformeng/test-tile-test
