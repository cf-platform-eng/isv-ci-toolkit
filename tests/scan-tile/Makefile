PIPENV := $(shell command -v pipenv 2> /dev/null)

pipenv:
ifndef PIPENV
	pip install pipenv
endif
    $(NOOP)

temp/make-tags/scan-tile: Pipfile.lock pipenv
	unset PYTHONPATH &&	pipenv sync --dev
	mkdir -p temp/make-tags
	touch temp/make-tags/scan-tile

clean:
	rm -rf temp

#### DEPS ####
deps: temp/make-tags/scan-tile

test: deps
	pipenv run python scan_tile_test.py
	pipenv run python scan_tile_integration_test.py

build:
	docker build . -t cfplatformenv/scan-tile

tile-path:
ifndef TILE_PATH
	$(error TILE_PATH not defined. Set this with the full path to your .pivotal tile)
else
	$(NOOP)
endif

logs:
	mkdir -p ./logs

run: tile-path logs
	docker run \
		-v ${TILE_PATH}:/input/tile.pivotal \
		cfplatformenv/scan-tile 2>&1 | tee ./logs/$(shell date "+%Y.%m.%d-%H.%M.%S").log

shell: tile-path
	docker run -it \
		-v ${TILE_PATH}:/input/tile.pivotal \
		cfplatformenv/scan-tile bash
