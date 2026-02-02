IMAGE_NAME := amp_in_a_box
REGISTRY := ghcr.io
# defaulting NAMESPACE to the current user if not set, change as needed
NAMESPACE ?= $(USER)
FULL_IMAGE_NAME := $(REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME)
TAG := latest

.PHONY: build build-proxy push pull run run-isolated

build: build-amp build-proxy

build-amp:
	podman build -t $(IMAGE_NAME) -f Containerfile .

build-proxy:
	podman build -t amp_proxy -f Containerfile.proxy .

# Tag the local image with the registry name before pushing
push:
	podman tag $(IMAGE_NAME) $(FULL_IMAGE_NAME):$(TAG)
	podman push $(FULL_IMAGE_NAME):$(TAG)

pull:
	podman pull $(FULL_IMAGE_NAME):$(TAG)

run:
	./runner.sh

run-isolated:
	./runner-sidecar.sh
