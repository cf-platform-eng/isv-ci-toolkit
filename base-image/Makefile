SHELL = /bin/bash
.PHONY: build clean publish run

clean:
	rm -rf temp

#
# Docker image targets
#
temp/make-tags/build: Dockerfile
	@docker build . --file Dockerfile --tag cfplatformeng/base-image:latest
	mkdir -p temp/make-tags && touch temp/make-tags/build

build: temp/make-tags/build

publish: build
	docker push cfplatformeng/base-image:latest

run: build
	docker run -it cfplatformeng/base-image:latest bash
