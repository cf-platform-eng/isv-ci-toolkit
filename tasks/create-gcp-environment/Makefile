.PHONY: lint test

temp/make-tags/deps:
	mkdir -p temp/make-tags
	touch temp/make-tags/deps
	curl https://raw.githubusercontent.com/grayhemp/bats-mock/master/src/bats-mock.bash > temp/bats-mock.bash

clean:
	rm -f temp/make-tags/deps

deps: temp/make-tags/deps

lint:
	shellcheck *.sh

test: deps lint
	bats --tap *.bats
