.PHONY: all build clean

LIB=go_piv_bindings.dylib

default: build

build:
	GOOS=darwin GOARCH=arm64 CGO_ENABLED=1 go build -buildmode=c-shared -o $(LIB)

clean:
	rm -f $(LIB) go_piv_bindings.h go_piv_bindings.c
