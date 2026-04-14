BIN_DIR := .bin
CLI := $(BIN_DIR)/ces-k3d

.PHONY: build
build:
	@mkdir -p $(BIN_DIR)
	go build -o $(CLI) ./cmd/ces-k3d

.PHONY: run
run: build
	$(CLI) $(ARGS)

.PHONY: test
test:
	go test ./...
