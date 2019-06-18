tile-location:

pas-config:	om-username om-password om-target
tile-config: tile-path tile-config-path

om-username:
ifndef OM_USERNAME
	$(error OM_USERNAME not defined)
else
	$(NOOP)
endif

om-password:
ifndef OM_PASSWORD
	$(error OM_PASSWORD not defined)
else
	$(NOOP)
endif

om-target:
ifndef OM_TARGET
	$(error OM_TARGET not defined)
else
	$(NOOP)
endif

tile-path:
ifndef TILE_PATH
	$(error TILE_PATH not defined)
else
	$(NOOP)
endif

tile-config-path:
ifndef TILE_CONFIG_PATH
	$(error TILE_CONFIG_PATH not defined)
else
	$(NOOP)
endif

pivnet-token:
ifndef PIVNET_TOKEN
	$(error PIVNET_TOKEN not defined)
else
	$(NOOP)
endif
scripts/upload_and_assign_stemcells.sh: ../config-image/upload_and_assign_stemcells.sh
	cp ../config-image/upload_and_assign_stemcells.sh scripts/upload_and_assign_stemcells.sh

run:  pas-config scripts/upload_and_assign_stemcells.sh tile-config
	docker run \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e PIVNET_TOKEN \
	-e TILE_NAME=$(shell basename "${TILE_PATH}") \
	-e TILE_CONFIG=$(shell basename "${TILE_CONFIG_PATH}") \
	-v $(shell dirname "${TILE_PATH}"):/tile \
	-v $(shell dirname "${TILE_CONFIG_PATH}"):/tile-config \
	-v $(shell pwd)/scripts:/scripts \
	gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
	/bin/bash -c "/scripts/pas-test.sh"

shell:  pas-config scripts/upload_and_assign_stemcells.sh tile-config
	docker run -it \
	-e OM_USERNAME \
	-e OM_PASSWORD \
	-e OM_TARGET \
	-e PIVNET_TOKEN \
	-e TILE_NAME=$(shell basename "${TILE_PATH}") \
	-e TILE_CONFIG=$(shell basename "${TILE_CONFIG_PATH}") \
	-v $(shell dirname "${TILE_PATH}"):/tile \
	-v $(shell dirname "${TILE_CONFIG_PATH}"):/tile-config \
	-v $(shell pwd)/scripts:/scripts \
	gcr.io/fe-rabbit-mq-tile-ci/base-test-image:latest \
	/bin/bash