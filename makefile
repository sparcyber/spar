# Project
MODULE   := github.com/sparcyber/spar
BINARY   := spar

# Version info
VERSION  ?= $(shell git describe --tags --always --dirty 2>/dev/null || echo "dev")
COMMIT   ?= $(shell git rev-parse --short HEAD 2>/dev/null || echo "unknown")
DATE     ?= $(shell date -u +%Y-%m-%dT%H:%M:%SZ)
LDFLAGS  := -X $(MODULE)/internal/version.Version=$(VERSION) \
            -X $(MODULE)/internal/version.Commit=$(COMMIT) \
            -X $(MODULE)/internal/version.Date=$(DATE)

# Tools
GOLANGCI_LINT_VERSION := v1.62.2

.PHONY: build test test-race test-integration lint fmt vet clean install tools

## Build

build:
	go build -ldflags "$(LDFLAGS)" -o bin/$(BINARY) ./cmd/spar

install:
	go install -ldflags "$(LDFLAGS)" ./cmd/spar

## Test

test:
	go test ./...

test-race:
	go test -race ./...

test-integration:
	go test -tags=integration -race ./...

## Quality

lint: tools
	golangci-lint run ./...

fmt:
	gofumpt -w .
	goimports -w .

vet:
	go vet ./...

## Housekeeping

clean:
	rm -rf bin/

tools:
	@which golangci-lint > /dev/null 2>&1 || \
		go install github.com/golangci/golangci-lint/cmd/golangci-lint@$(GOLANGCI_LINT_VERSION)
	@which gofumpt > /dev/null 2>&1 || \
		go install mvdan.cc/gofumpt@latest
	@which goimports > /dev/null 2>&1 || \
		go install golang.org/x/tools/cmd/goimports@latest

## CI (what GitHub Actions runs)

ci: lint vet test-race
