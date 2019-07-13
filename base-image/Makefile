.PHONY: build publish run clean

clean:
	rm -rf temp

#
# Depdendency targets
#

KSM_VERSION ?= 0.4.66
temp/ksm:
	mkdir -p temp
ifndef KSM_VERSION
	(cd temp && marman download-release --owner cf-platform-eng --repo ksm --filter "ksm-.*\.linux$$")
else
	(cd temp && marman download-release --owner cf-platform-eng --repo ksm --version $(KSM_VERSION) --filter "ksm-.*\.linux$$")
endif
	mv temp/ksm-$(KSM_VERSION).linux temp/ksm

PKSCTL_VERSION ?= 0.0.522
temp/pksctl:
	mkdir -p temp
ifndef PKSCTL_VERSION
	(cd temp && marman download-release --owner pivotal --repo pe-pixie --filter "linux$$")
else
	(cd temp && marman download-release --owner pivotal --repo pe-pixie --version $(PKSCTL_VERSION) --filter "linux$$")
endif
	mv temp/pksctl-$(PKSCTL_VERSION).linux temp/pksctl

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

temp/tileinspect:
	mkdir -p temp
ifndef TILEINSPECT_VERSION
	(cd temp && marman download-release --owner cf-platform-eng --repo tileinspect --filter "tileinspect-linux")
else
	(cd temp && marman download-release --owner cf-platform-eng --repo tileinspect --version ${TILEINSPECT_VERSION} --filter "tileinspect-linux")
endif
	mv temp/tileinspect-linux temp/tileinspect

temp/marman:
	mkdir -p temp
ifndef MARMAN_VERSION
	(cd temp && marman download-release --owner cf-platform-eng --repo marman --filter "marman-linux")
else
	(cd temp && marman download-release --owner cf-platform-eng --repo marman --version ${MARMAN_VERSION} --filter "marman-linux")
endif
	mv temp/marman-linux temp/marman

temp/needs:
	mkdir -p temp
ifndef NEEDS_VERSION
	(cd temp && marman download-release --owner cf-platform-eng --repo needs --filter "needs-linux")
else
	(cd temp && marman download-release --owner cf-platform-eng --repo needs --version ${NEEDS_VERSION} --filter "needs-linux")
endif
	mv temp/needs-linux temp/needs

temp/mrlog:
	mkdir -p temp
ifndef MRLOG_VERSION
	(cd temp && marman download-release --owner cf-platform-eng --repo mrlog --filter "mrlog-linux")
else
	(cd temp && marman download-release --owner cf-platform-eng --repo mrlog --version ${NEEDS_VERSION} --filter "mrlog-linux")
endif
	mv temp/mrlog-linux temp/mrlog

#
# Docker image targets
#
temp/phony/cfplatformeng/test-ksm-ci: temp/ksm temp/marman temp/ops-manifest.gem temp/pks temp/pksctl temp/tileinspect temp/needs temp/mrlog Dockerfile
	docker build . --file Dockerfile --tag gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
		--build-arg KSM_CLI_PATH=temp/ksm \
		--build-arg MARMAN_PATH=temp/marman \
		--build-arg OPS_MANIFEST_PATH=temp/ops-manifest.gem \
		--build-arg PKS_CLI_PATH=temp/pks \
		--build-arg PKSCTL_PATH=temp/pksctl \
		--build-arg NEEDS_PATH=temp/needs \
		--build-arg MRLOG_PATH=temp/mrlog \
		--build-arg TILE_INSPECT_PATH=temp/tileinspect
	mkdir -p temp/phony/cfplatformeng && touch temp/phony/cfplatformeng/test-ksm-ci

build: temp/phony/cfplatformeng/test-ksm-ci

publish: build
	echo "WARNING: this image contains files that are not fit for public release.  DO NOT PUBLISH PUBLICLY"
	docker push gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest

run: build
	docker run -it gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest bash
