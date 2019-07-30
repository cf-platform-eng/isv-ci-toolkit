.PHONY: lint test

temp/make-tags/deps:
	unset PYTHONPATH && pipenv sync --dev
	mkdir -p temp/make-tags
	touch temp/make-tags/deps
	pipenv run -- pipenv install
	curl https://raw.githubusercontent.com/cf-platform-eng/bats-mock/master/src/bats-mock.bash > temp/bats-mock.bash

clean:
	rm -f temp/make-tags/deps

deps: temp/make-tags/deps

lint:
	shellcheck *.sh

test: deps lint
	pipenv run -- bats --tap *.bats
