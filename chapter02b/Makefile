SHELL := bash

# Prerequisite tools
GO                 ?= go
YARN               ?= yarn
DOCKER             ?= docker
FIND               ?= find
TMUX               ?= tmux
GOLANGCI_LINT      ?= golangci-lint

CMD_DOGCAT = dogcat
CMD_DOGCAT_SRC = cmd/dogcat/main.go

.EXPORT_ALL_VARIABLES:
.PHONY: export entgen dev build


build: $(CMD_DOGCAT)

$(CMD_DOGCAT): $(shell $(FIND) . -type f -name '*.go') export
	$(GO) build -o $(CMD_DOGCAT) -a $(BUILDFLAGS) $(LDFLAGS) $(CMD_DOGCAT_SRC)

export:
	cd web; $(YARN) run export

entgen:
	$(GO) generate ./ent

dev:
	$(TMUX) -S /tmp/dogcat-tmux \
		new-session  'cd web; yarn run dev' \; \
		split-window "reflex -r '\.go$$' -s -- go run cmd/dogcat/main.go server --dev"
