.PHONY: build set-pipeline set-scan-tile-pipeline set-test-tile-pipeline test

test:
	$(MAKE) -C tools test
	$(MAKE) -C tests/install-uninstall-pas-tile test
	$(MAKE) -C tasks/config-image test
	$(MAKE) -C tasks/create-gcp-environment test
	$(MAKE) -C tasks/teardown-environment test

build: test
	$(MAKE) -C base-image build
	$(MAKE) -C images build
	$(MAKE) -C tasks/config-and-upgrade-image build
	$(MAKE) -C tasks/config-and-upgrade-product-image build
	$(MAKE) -C tasks/config-image build
	$(MAKE) -C tasks/config-pks-image build
	$(MAKE) -C tasks/create-gcp-environment build
	$(MAKE) -C tasks/teardown-environment build
	$(MAKE) -C tests/install-uninstall-pas-tile build

set-pipeline: ci/pipeline.yaml
	fly -t ppe-isv set-pipeline -p isv-ci-toolkit -c ci/pipeline.yaml

set-scan-tile-pipeline: tests/scan-tile/ci/pipeline.yaml
	fly -t ppe-isv set-pipeline -p scan-tile -c tests/scan-tile/ci/pipeline.yaml

set-test-tile-pipeline: tests/install-uninstall-pas-tile/ci/pipeline.yaml
	fly -t ppe-isv set-pipeline -p install-uninstall-pas -c tests/install-uninstall-pas-tile/ci/pipeline.yaml
