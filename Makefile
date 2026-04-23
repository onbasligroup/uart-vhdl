# uart-vhdl Makefile

SHELL := /bin/bash

ROOT_DIR := $(shell pwd)
SRC_DIR := $(ROOT_DIR)/src
TB_DIR := $(ROOT_DIR)/tb
BUILD_DIR := $(ROOT_DIR)/build
WORK_DIR := $(BUILD_DIR)/work

GHDL := ghdl
GHDL_STD := --std=08
GHDL_FLAGS := $(GHDL_STD) --workdir=$(WORK_DIR)

PYTHON := python3
DOCKER_IMAGE := uart-vhdl:latest

SRCS := \
	$(SRC_DIR)/uart_tx.vhd \
	$(SRC_DIR)/uart_rx.vhd

.PHONY: help check-tools dirs clean analyze test cocotb-test docker-build docker-test

help:
	@echo "uart-vhdl targets:"
	@echo "  make analyze       Analyze RTL with GHDL"
	@echo "  make test          Alias of analyze (compile smoke check)"
	@echo "  make cocotb-test   Run cocotb regression suite"
	@echo "  make docker-build  Build Docker image"
	@echo "  make docker-test   Run cocotb regression inside Docker"
	@echo "  make clean         Remove build artifacts"

check-tools:
	@command -v $(GHDL) >/dev/null 2>&1 || (echo "Error: ghdl not found" && exit 1)
	@command -v $(PYTHON) >/dev/null 2>&1 || (echo "Error: python3 not found" && exit 1)

dirs:
	@mkdir -p $(WORK_DIR)
	@mkdir -p $(BUILD_DIR)

clean:
	@rm -rf $(BUILD_DIR)
	@find $(ROOT_DIR) -type f -name "*.cf" -delete

analyze: check-tools dirs
	@echo ">>> Analyzing UART sources with GHDL"
	@for src in $(SRCS); do \
		$(GHDL) -a $(GHDL_FLAGS) "$$src" || exit 1; \
	done
	@echo "OK: analyze"

test: analyze

cocotb-test: dirs
	@echo ">>> Running cocotb UART regression"
	@$(PYTHON) $(ROOT_DIR)/scripts/run_cocotb.py

docker-build:
	@docker build -t $(DOCKER_IMAGE) $(ROOT_DIR)

docker-test: docker-build
	@docker run --rm -v $(ROOT_DIR):/workspace -w /workspace $(DOCKER_IMAGE) make cocotb-test
