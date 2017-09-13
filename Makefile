
GO  := go
pkgs = $(shell $(GO) list ./... | grep -v /vendor/)

all:
	go build github.com/cofyc/mysqlops/cmd/mysqlops-exporter

test:
	$(GO) test $(pkgs)
.PHONY: test

style:
	@echo ">> checking code style"
	@! gofmt -d $(shell find . -path ./vendor -prune -o -name '*.go' -print) | grep '^'
.PHONY: style

fmt:
	@echo ">> formatting code"
	@$(GO) fmt $(pkgs)
.PHONY: fmt
