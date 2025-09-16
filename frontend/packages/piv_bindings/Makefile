SHELL := /bin/bash

# paths
GO_DIR := golang_piv_bindings
TEST_DYLIB_DIR := test/suite
OUT_DYLIB := $(TEST_DYLIB_DIR)/golang_piv_bindings.dylib
OUT_HEADER := $(TEST_DYLIB_DIR)/golang_piv_bindings.h

.PHONY: generate-go-bindings-for-tests clear-go-bindings-for-tests

## generate-go-bindings-for-tests: build c-shared dylib into test/dylib and remove generated header
generate-go-bindings-for-tests:
	@mkdir -p "$(TEST_DYLIB_DIR)"
	@echo "==> building golang test dylib -> $(OUT_DYLIB)"
	@if command -v xcrun >/dev/null 2>&1; then export SDKROOT="$$(xcrun --sdk macosx --show-sdk-path)"; fi; \
	CDIR="$$(pwd)"; \
	cd "$(GO_DIR)" && SDKROOT="$$SDKROOT" CGO_ENABLED=1 GOOS=darwin GOARCH=arm64 go build -buildmode=c-shared -o "$$CDIR/$(OUT_DYLIB)"
	@rm -f "$(OUT_HEADER)"
	@echo "==> built $(OUT_DYLIB)"

## clear-go-bindings-for-tests: remove test dylib and header
clear-go-bindings-for-tests:
	@echo "==> removing $(OUT_DYLIB) and $(OUT_HEADER)"
	@rm -f "$(OUT_DYLIB)" "$(OUT_HEADER)"
	@echo "==> done"


