SHELL = /bin/bash
.PHONY: build publish run clean

clean:
	rm -rf temp

# todo: remove this once Marman has a clearer message (and perhaps a way to use the existing shell creds)
github-token:
ifndef GITHUB_TOKEN
	$(error GITHUB_TOKEN not defined, ISV-CI team use: 'credhub get -n /concourse/main/pipeline-secrets -k cfeng-repo-key')
else
	$(NOOP)
endif

pivnet-token:
ifndef PIVNET_TOKEN
	$(error PIVNET_TOKEN not defined)
else
	$(NOOP)
endif


#
# Docker image targets
#
temp/phony/cfplatformeng/test-ksm-ci: pivnet-token github-token Dockerfile
	@docker build . --file Dockerfile --tag gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
		--build-arg GITHUB_TOKEN=${GITHUB_TOKEN} \
		--build-arg PIVNET_TOKEN=${PIVNET_TOKEN} 
	mkdir -p temp/phony/cfplatformeng && touch temp/phony/cfplatformeng/test-ksm-ci

build: temp/phony/cfplatformeng/test-ksm-ci

publish: build
	echo "WARNING: this image contains files that are not fit for public release.  DO NOT PUBLISH PUBLICLY"
	docker push gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

run: build
	docker run -it gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest bash
