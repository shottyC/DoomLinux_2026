.PHONY: build clean docker-build-ubuntu docker-build-alpine docker-run-ubuntu docker-run-alpine docker-shell-ubuntu docker-shell-alpine test-smoke test-bdd test

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

test-smoke:
	./tests/smoke.sh

test-bdd:
	python3 -m pip install --user -r tests/requirements.txt
	python3 -m behave tests/features

test: test-smoke test-bdd
