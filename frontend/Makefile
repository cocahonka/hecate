SHELL := /bin/bash

-include .env
export

BINDINGS_DIST_DIR := bindings_dist
OUT_DYLIB := $(BINDINGS_DIST_DIR)/$(BINDINGS_DYLIB_NAME)
OUT_HEADER := $(OUT_DYLIB:.dylib=.h)

# tooling
GO ?= go
CODESIGN ?= codesign
SDKROOT ?= $(shell xcrun --sdk macosx --show-sdk-path)

.PHONY: all build_bindings sign_bindings clean_bindings print_env

## all: clean, build and sign bindings
all: clean_bindings build_bindings sign_bindings

## build_bindings: build bindings
build_bindings:
	@mkdir -p "$(BINDINGS_DIST_DIR)"
ifeq ($(BINDINGS_TYPE),GOLANG)
	@echo "==> building golang bindings -> $(OUT_DYLIB)"
	@cd "$(BINDINGS_GOLANG_DIR)" && \
		SDKROOT="$(SDKROOT)" CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 \
		$(GO) build -buildmode=c-shared -o "$(CURDIR)/$(OUT_DYLIB)"
	@echo "==> built $(OUT_DYLIB)"
	@rm -f "$(OUT_HEADER)"
	@echo
else
	$(error unsupported BINDINGS_TYPE=$(BINDINGS_TYPE). expected: GOLANG)
endif

## sign_bindings: ad-hoc sign built dylib (xcode re-signs inside .app)
sign_bindings:
	@echo "==> ad-hoc signing $(OUT_DYLIB)"
	@$(CODESIGN) -s - --force "$(OUT_DYLIB)"
	@echo "==> codesign done"
	@echo

## clean_bindings: remove built artifacts from bindings_dist
clean_bindings:
	@echo "==> cleaning $(BINDINGS_DIST_DIR)"
	@rm -f "$(BINDINGS_DIST_DIR)/*.dylib" "$(BINDINGS_DIST_DIR)/*.h"
	@echo "==> clean done"
	@echo

## print_env: print effective env and tooling info
print_env:
	@echo "BINDINGS_DIST_DIR  : $(BINDINGS_DIST_DIR)"
	@echo "BINDINGS_DYLIB_NAME: $(BINDINGS_DYLIB_NAME)"
	@echo "BINDINGS_TYPE      : $(BINDINGS_TYPE)"
	@echo "BINDINGS_GOLANG_DIR: $(BINDINGS_GOLANG_DIR)"
	@echo "SDKROOT            : $(SDKROOT)"
	@$(GO) version



