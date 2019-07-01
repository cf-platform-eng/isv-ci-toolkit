.PHONY: lint test

lint:
	shellcheck *.sh

test: lint
	bats *.bats
