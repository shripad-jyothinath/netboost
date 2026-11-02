SHELL := /bin/sh

.PHONY: all fetch build lint test install clean

all: build

fetch:
	@scripts/fetch-band-tool.sh

build:
	@scripts/build.sh

lint:
	@tests/lint.sh

test: lint
	@tests/smoke.sh

install: build
	@scripts/install.sh

clean:
	rm -rf build
