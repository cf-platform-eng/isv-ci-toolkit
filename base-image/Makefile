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

#
# Depdendency targets
#

OPS_MANIFEST_VERSION ?= 2.7.0-internalDev.39
OPS_MANIFEST_FILE_NAME = $(shell pivnet product-files --product-slug pivotal-ops-manifest --release-version $(OPS_MANIFEST_VERSION) --format=json | jq -r '.[0].aws_object_key' | xargs basename)
OPS_MANIFEST_FILE_ID = $(shell pivnet product-files --product-slug pivotal-ops-manifest --release-version $(OPS_MANIFEST_VERSION) --format=json | jq -r '.[0].id')
temp/ops-manifest.gem:
	mkdir -p temp
	touch temp/$(OPS_MANIFEST_FILE_NAME)
	pivnet download-product-files \
		--accept-eula \
		--product-slug pivotal-ops-manifest \
		--release-version $(OPS_MANIFEST_VERSION) \
		--product-file-id $(OPS_MANIFEST_FILE_ID) \
		--download-dir temp
	mv temp/$(OPS_MANIFEST_FILE_NAME) temp/ops-manifest.gem

PKS_VERSION ?= 1.4.0
PKS_FILE_NAME = $(shell pivnet product-files --product-slug pivotal-container-service --release-version $(PKS_VERSION) --format=json | jq -r '.[] | select(.name=="PKS CLI - Linux") | .aws_object_key' | xargs basename)
PKS_FILE_ID = $(shell pivnet product-files --product-slug pivotal-container-service --release-version $(PKS_VERSION) --format=json | jq -r '.[] | select(.name=="PKS CLI - Linux") | .id')
temp/pks:
	mkdir -p temp
	touch temp/$(PKS_FILE_NAME)
	pivnet download-product-files \
		--accept-eula \
		--product-slug pivotal-container-service \
		--release-version $(PKS_VERSION) \
		--product-file-id $(PKS_FILE_ID) \
		--download-dir temp
	mv temp/$(PKS_FILE_NAME) temp/pks

#
# Docker image targets
#
temp/phony/cfplatformeng/test-ksm-ci: temp/ops-manifest.gem temp/pks Dockerfile
	docker build . --file Dockerfile --tag gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
		--build-arg OPS_MANIFEST_PATH=temp/ops-manifest.gem \
		--build-arg PKS_CLI_PATH=temp/pks \
		--build-arg GITHUB_TOKEN=${GITHUB_TOKEN}
	mkdir -p temp/phony/cfplatformeng && touch temp/phony/cfplatformeng/test-ksm-ci

build: temp/phony/cfplatformeng/test-ksm-ci

publish: build
	echo "WARNING: this image contains files that are not fit for public release.  DO NOT PUBLISH PUBLICLY"
	docker push gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

run: build
	docker run -it gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest bash
