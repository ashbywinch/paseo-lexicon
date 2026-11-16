SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

NODE := node
NPM := npm

.PHONY: help setup deps tools lint lint-check typecheck test coverage format clean check secret-set

# Tooling runs from the project's own venv with a pinned interpreter: the system Python is irrelevant.
UV ?= uv
PYTHON_VERSION ?= 3.14
TOOLS_VENV ?= .tools/venv
TOOLS_PYTHON := $(TOOLS_VENV)/bin/python

REPO ?= ashbywinch/paseo-lexicon
SECRET ?= PASEO_LEXICON_API_KEY
SECRET_VALUE_VAR ?= CLOUDFLARE_AIGATEWAY_TOKEN

help:
	@echo "paseo-lexicon"
	@echo "  make setup      install dependencies"
	@echo "  make lint       report lint findings"
	@echo "  make typecheck  tsc --noEmit"
	@echo "  make test       typecheck + tests (the gate)"
	@echo "  make coverage   tests with a clover report in coverage/"
	@echo "  make format     rewrite formatting in place"
	@echo "  make check      lint + typecheck, what pre-push runs"
	@echo "  make secret-set set $(SECRET) on $(REPO) from \$$$(SECRET_VALUE_VAR)"
	@echo "  make clean      remove node_modules, coverage, build residue"

setup: deps

deps:
	$(NPM) install
	@if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi

lint:
	$(NPM) run lint

lint-check:
	$(NPM) run lint:check

typecheck:
	$(NPM) run typecheck

test: typecheck
	$(NPM) run test

coverage:
	$(NPM) run coverage

format:
	$(NPM) run format

# Repo operations: a venv with a pinned interpreter, provisioned here rather than borrowed from the
# system. Idempotent — an existing venv with the right version is reused.
tools:
	@test -x $(TOOLS_PYTHON) || $(UV) venv --python $(PYTHON_VERSION) $(TOOLS_VENV)
	@$(UV) pip install --quiet --python $(TOOLS_PYTHON) pynacl

secret-set: tools
	@$(TOOLS_PYTHON) tools/set_secret.py "$(REPO)" "$(SECRET)" "$(SECRET_VALUE_VAR)"

clean:
	rm -rf node_modules coverage .vitest dist .tools

# The single gate CI and the pre-push hook both run: no drift between them.
check: lint-check typecheck
