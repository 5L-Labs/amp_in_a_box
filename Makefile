# Amp in a Box - Makefile
# Build, run, and manage Amp sandbox containers with network filtering (Podman)

.PHONY: build build-amp build-proxy push push-proxy pull run run-isolated stop clean help

# ==============================================================================
# Variables (all overridable via command line or environment)
# ==============================================================================

# Project directory to mount (required for run-isolated target)
PROJECT ?= 

# Container image settings
IMAGE_NAME := amp_in_a_box
PROXY_IMAGE_NAME := amp_proxy
REGISTRY ?= ghcr.io
NAMESPACE ?= $(USER)
TAG ?= latest

# Full image names for registry
FULL_IMAGE_NAME := $(REGISTRY)/$(NAMESPACE)/$(IMAGE_NAME)
FULL_PROXY_IMAGE_NAME := $(REGISTRY)/$(NAMESPACE)/$(PROXY_IMAGE_NAME)

# ==============================================================================
# Pre-flight checks
# ==============================================================================

define check_podman
	@command -v podman >/dev/null 2>&1 || { \
		echo "Error: Podman is not installed or not in PATH"; \
		echo "Install Podman: https://podman.io/getting-started/installation"; \
		exit 1; \
	}
endef

define check_project
	@if [ -z "$(PROJECT)" ]; then \
		echo "Error: PROJECT is required"; \
		echo ""; \
		echo "Usage: make run-isolated PROJECT=/path/to/your/project"; \
		echo ""; \
		echo "Run 'make help' for more information."; \
		exit 1; \
	fi
	@if [ ! -d "$(PROJECT)" ]; then \
		echo "Error: PROJECT directory does not exist: $(PROJECT)"; \
		exit 1; \
	fi
endef

# ==============================================================================
# Targets
# ==============================================================================

## build: Build both container images (amp and proxy)
build: build-amp build-proxy

## build-amp: Build the Amp sandbox container
build-amp:
	$(call check_podman)
	podman build -t $(IMAGE_NAME) -f Containerfile .

## build-proxy: Build the Squid proxy sidecar container
build-proxy:
	$(call check_podman)
	podman build -t $(PROXY_IMAGE_NAME) -f Containerfile.proxy .

## push: Push amp image to registry
push:
	$(call check_podman)
	podman tag $(IMAGE_NAME) $(FULL_IMAGE_NAME):$(TAG)
	podman push $(FULL_IMAGE_NAME):$(TAG)

## push-proxy: Push proxy image to registry
push-proxy:
	$(call check_podman)
	podman tag $(PROXY_IMAGE_NAME) $(FULL_PROXY_IMAGE_NAME):$(TAG)
	podman push $(FULL_PROXY_IMAGE_NAME):$(TAG)

## push-all: Push both images to registry
push-all: push push-proxy

## pull: Pull amp image from registry
pull:
	$(call check_podman)
	podman pull $(FULL_IMAGE_NAME):$(TAG)

## run: Run amp container directly (no network filtering)
run:
	$(call check_podman)
	./runner.sh

## run-isolated: Run amp with proxy sidecar (requires PROJECT)
run-isolated:
	$(call check_podman)
	$(call check_project)
	AMP_PROJECT=$(PROJECT) ./runner-sidecar.sh

## stop: Stop running proxy container
stop:
	$(call check_podman)
	-podman stop amp-proxy 2>/dev/null
	-podman rm amp-proxy 2>/dev/null
	@echo "Containers stopped."

## clean: Remove containers and images
clean:
	$(call check_podman)
	-podman stop amp-proxy 2>/dev/null
	-podman rm amp-proxy 2>/dev/null
	-podman rmi $(IMAGE_NAME) $(PROXY_IMAGE_NAME) 2>/dev/null
	-podman rmi $(FULL_IMAGE_NAME):$(TAG) $(FULL_PROXY_IMAGE_NAME):$(TAG) 2>/dev/null
	@echo "Clean complete."

## help: Show usage with all variables documented
help:
	@echo "Amp in a Box - Makefile (Podman)"
	@echo ""
	@echo "Usage:"
	@echo "  make <target> [VARIABLE=value ...]"
	@echo ""
	@echo "Targets:"
	@echo "  build         Build both container images"
	@echo "  build-amp     Build Amp sandbox container only"
	@echo "  build-proxy   Build Squid proxy sidecar only"
	@echo "  push          Push amp image to registry"
	@echo "  push-proxy    Push proxy image to registry"
	@echo "  push-all      Push both images to registry"
	@echo "  pull          Pull amp image from registry"
	@echo "  run           Run amp container directly (no filtering)"
	@echo "  run-isolated  Run amp with proxy sidecar (filtered network)"
	@echo "  stop          Stop running containers"
	@echo "  clean         Remove containers and images"
	@echo "  help          Show this help message"
	@echo ""
	@echo "Variables:"
	@echo "  PROJECT     Project directory to mount at /worktree (REQUIRED for run-isolated)"
	@echo "              Example: PROJECT=/home/user/myproject"
	@echo ""
	@echo "  NAMESPACE   Registry namespace (default: $$USER)"
	@echo "  TAG         Image tag (default: latest)"
	@echo ""
	@echo "Note: Amp config directories ($$HOME/.config, .amp, .local, .cache)"
	@echo "      are automatically mounted based on your $$HOME and $$USER."
	@echo ""
	@echo "Examples:"
	@echo "  make build"
	@echo "  make run-isolated PROJECT=/home/user/myproject"
	@echo "  make push TAG=v1.0.0"