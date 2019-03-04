SHELL = /bin/bash
default: build


build:
	$(MAKE) --directory ../tileinspect build
	cp ../tileinspect/build/tileinspect artifacts
	docker build . -t cfplatformeng/test-tile-test
