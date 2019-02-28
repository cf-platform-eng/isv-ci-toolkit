SHELL = /bin/bash
GO-VER = go1.11.5

default: build

# #### GO Binary Management ####
deps-go-binary:
	echo "Expect: $(GO-VER)" && \
		echo "Actual: $$(go version)" && \
	 	go version | grep $(GO-VER) > /dev/null


HAS_GO_IMPORTS := $(shell command -v goimports;)

deps-goimports: deps-go-binary
ifndef HAS_GO_IMPORTS
	go get -u golang.org/x/tools/cmd/goimports
endif

# #### CLEAN ####
clean: deps-go-binary
	rm -rf build/*
	go clean --modcache


# #### DEPS ####

deps: deps-goimports deps-go-binary
	go mod download

# #### BUILD ####
SRC = $(shell find . -name "*.go" | grep -v "_test\." )

build/tileinspect: $(SRC) deps
	go build -o build/tileinspect ./cmd/tileinspect/main.go

build: build/tileinspect
