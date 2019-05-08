.PHONY: build publish run clean

#
# Depdendency targets
#
temp:
	mkdir -p temp

clean:
	rm -rf temp

BAZAAR_VERSION ?= 0.4.33
temp/bazaar: temp temp/marman
	(cd temp && ./marman download-release -o cf-platform-eng -r bazaar -v $(BAZAAR_VERSION) -f "linux$$")
	mv temp/bazaar-$(BAZAAR_VERSION).linux temp/bazaar

PKSCTL_VERSION ?= 0.0.502
temp/pksctl: temp temp/marman
	(cd temp && ./marman download-release -o pivotal -r pe-pixie -v $(PKSCTL_VERSION) -f "linux$$")
	mv temp/pksctl-$(PKSCTL_VERSION).linux temp/pksctl

OPS_MANIFEST_VERSION ?= 2.6.0-internalDev.93
OPS_MANIFEST_FILE_NAME = $(shell pivnet product-files --product-slug pivotal-ops-manifest --release-version $(OPS_MANIFEST_VERSION) --format=json | jq -r '.[0].aws_object_key' | xargs basename)
OPS_MANIFEST_FILE_ID = $(shell pivnet product-files --product-slug pivotal-ops-manifest --release-version $(OPS_MANIFEST_VERSION) --format=json | jq -r '.[0].id')
temp/ops-manifest.gem: temp
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
temp/pks: temp
	touch temp/$(PKS_FILE_NAME)
	pivnet download-product-files \
		--accept-eula \
		--product-slug pivotal-container-service \
		--release-version $(PKS_VERSION) \
		--product-file-id $(PKS_FILE_ID) \
		--download-dir temp
	mv temp/$(PKS_FILE_NAME) temp/pks

temp/tileinspect: temp
	(cd tileinspect && GOOS=linux GOARCH=amd64 make build)
	cp tileinspect/build/tileinspect temp/tileinspect

temp/marman: temp
	(cd marman && make build)
	cp marman/build/marman temp/marman

#
# Docker image targets
#
temp/phony/cfplatformeng/test-bazaar-ci: temp/bazaar temp/marman temp/ops-manifest.gem temp/pks temp/pksctl temp/tileinspect Dockerfile.base
	docker build . --file Dockerfile.base --tag gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
		--build-arg BAZAAR_CLI_PATH=temp/bazaar \
		--build-arg MARMAN_PATH=temp/marman \
		--build-arg OPS_MANIFEST_PATH=temp/ops-manifest.gem \
		--build-arg PKS_CLI_PATH=temp/pks \
		--build-arg PKSCTL_PATH=temp/pksctl \
#		--build-arg TILE_INSPECT_PATH=temp/tileinspect
	mkdir -p temp/phony/cfplatformeng && touch temp/phony/cfplatformeng/test-bazaar-ci

build: temp/phony/cfplatformeng/test-bazaar-ci

publish: build
	echo "WARNING: this image contains files that are not fit for public release.  DO NOT PUBLISH PUBLICLY"
	docker push gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

run: build
	docker run -it gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest bash
