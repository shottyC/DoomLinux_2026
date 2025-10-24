.PHONY: build clean docker-build-ubuntu docker-build-alpine docker-run-ubuntu docker-run-alpine docker-shell-ubuntu docker-shell-alpine lint lint-shellcheck lint-shfmt test-smoke test-bdd test

build:
	./DoomLinux.sh

clean:
	rm -rf rootfs staging iso DoomLinux.iso

docker-build-ubuntu:
	docker build -f docker/Dockerfile.ubuntu -t doomlinux:ubuntu .

docker-build-alpine:
	docker build -f docker/Dockerfile.alpine -t doomlinux:alpine .

docker-run-ubuntu: docker-build-ubuntu
	docker run --rm -v $(CURDIR):/workspace -w /workspace doomlinux:ubuntu ./DoomLinux.sh

docker-run-alpine: docker-build-alpine
	docker run --rm -v $(CURDIR):/workspace -w /workspace doomlinux:alpine ./DoomLinux.sh

docker-shell-ubuntu: docker-build-ubuntu
	docker run --rm -it -v $(CURDIR):/workspace -w /workspace doomlinux:ubuntu /bin/bash

docker-shell-alpine: docker-build-alpine
	docker run --rm -it -v $(CURDIR):/workspace -w /workspace doomlinux:alpine /bin/sh

lint: lint-shellcheck lint-shfmt

lint-shellcheck:
	@if command -v shellcheck >/dev/null 2>&1; then \
		shellcheck DoomLinux.sh tests/smoke.sh; \
	else \
		docker run --rm -v $(CURDIR):/workspace -w /workspace koalaman/shellcheck:stable DoomLinux.sh tests/smoke.sh; \
	fi

lint-shfmt:
	@if command -v shfmt >/dev/null 2>&1; then \
		shfmt -d DoomLinux.sh tests/smoke.sh; \
	else \
		docker run --rm -v $(CURDIR):/workspace -w /workspace mvdan/shfmt -d DoomLinux.sh tests/smoke.sh; \
	fi

test-smoke:
	./tests/smoke.sh

test-bdd:
	python3 -m pip install --user -r tests/requirements.txt
	python3 -m behave tests/features

test: test-smoke test-bdd
