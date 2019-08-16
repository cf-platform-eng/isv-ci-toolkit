.PHONY: lint test

MRLOG := $(shell command -v mrlog 2> /dev/null)

mrlog:
ifndef MRLOG
    $(error "please instal mrlog https://github.com/cf-platform-eng/mrlog/releases/latest")
endif
    $(NOOP)

temp/make-tags/deps:
	unset PYTHONPATH && pipenv sync --dev
	mkdir -p temp/make-tags
	touch temp/make-tags/deps
	pipenv run -- pipenv install
	curl https://raw.githubusercontent.com/cf-platform-eng/bats-mock/master/src/bats-mock.bash > temp/bats-mock.bash

clean:
	rm -f temp/make-tags/deps

deps: temp/make-tags/deps mrlog

lint:
	shellcheck *.sh

test: deps lint
	pipenv run -- bats --tap *.bats

SCRIPTS := $(shell ls *.sh)
build-image: $(SCRIPTS)
	docker build --tag cfplatformeng/isv-ci-toolkit:dev --file Dockerfile .
