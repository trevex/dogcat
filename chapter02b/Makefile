SHELL := bash

# Prerequisite tools
GO                 ?= go
YARN               ?= yarn
DOCKER             ?= docker
FIND               ?= find
TMUX               ?= tmux
GOLANGCI_LINT      ?= golangci-lint

.EXPORT_ALL_VARIABLES:
.PHONY: export entgen dev

export:
	cd web; $(YARN) run export

entgen:
	$(GO) generate ./ent

dev:
	$(TMUX) -S /tmp/dogcat-tmux \
		new-session  'cd web; yarn run dev' \; \
		split-window "reflex -r '\.go$$' -s -- go run cmd/dogcat/main.go server --dev"
