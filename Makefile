test:
	$(MAKE) -C tools test
	$(MAKE) -C tests/install-uninstall-pas-tile test
	$(MAKE) -C tasks/config-image test
	$(MAKE) -C tasks/create-gcp-environment test
	$(MAKE) -C tasks/teardown-environment test
