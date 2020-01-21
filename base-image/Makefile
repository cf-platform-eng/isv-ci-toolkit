SHELL = /bin/bash
.PHONY: build clean publish run

clean:
	rm -rf temp

#
# Docker image targets
#
temp/make-tags/build: Dockerfile jeb.sh
	@docker build . --file Dockerfile --tag cfplatformeng/base-image:local
	mkdir -p temp/make-tags && touch temp/make-tags/build

build: temp/make-tags/build

publish: build
	docker push cfplatformeng/base-image:latest

shell: build
	docker run -it --rm -v ${PWD}:/root cfplatformeng/base-image:local shell
