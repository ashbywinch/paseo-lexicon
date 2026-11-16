SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

NODE := node
NPM := npm

.PHONY: help install setup deps tools install-hooks lint lint-check lint-github typecheck test coverage format merge-markers clean check secret-set

# Tooling runs from the project's own venv with a pinned interpreter: the system Python is irrelevant.
UV ?= uv
PYTHON_VERSION ?= 3.14
TOOLS_BIN ?= .tools/bin
TOOLS_VENV ?= .tools/venv
TOOLS_PYTHON := $(TOOLS_VENV)/bin/python

REPO ?= ashbywinch/paseo-lexicon
SECRET ?= PASEO_LEXICON_API_KEY
SECRET_VALUE_VAR ?= CLOUDFLARE_AIGATEWAY_TOKEN

help:
	@echo "paseo-lexicon"
	@echo "  make install    everything in one shot: deps, .env, hooks, tools venv"
	@echo "  make setup      dependencies only"
	@echo "  make lint       report lint findings"
	@echo "  make typecheck  tsc --noEmit"
	@echo "  make test       typecheck + tests (the gate)"
	@echo "  make coverage   tests with a clover report in coverage/"
	@echo "  make format     rewrite formatting in place"
	@echo "  make check      lint + typecheck, what pre-push runs"
	@echo "  make secret-set set $(SECRET) on $(REPO) from \$$$(SECRET_VALUE_VAR)"
	@echo "  make merge-markers  fail on a committed conflict marker"
	@echo "  make clean      remove node_modules, coverage, build residue"

# One shot for a fresh clone. `secret-set` stays separate: it needs an ambient token.
install: setup tools
	@echo "Installed. Next: make test, or make secret-set when CLOUDFLARE_AIGATEWAY_TOKEN is set."

setup: deps install-hooks

deps:
	$(NPM) install
	@if [ -f .env.example ] && [ ! -f .env ]; then cp .env.example .env; fi

lint:
	$(NPM) run lint

lint-check: deps
	$(NPM) run lint:check

# CI only: findings surface as PR annotations.
lint-github: deps
	$(NPM) run lint:github

typecheck: deps
	$(NPM) run typecheck

merge-markers: deps
	@tools/check-merge-markers.sh

install-hooks: deps
	@npx husky >/dev/null 2>&1 || true
	@git config core.hooksPath >/dev/null 2>&1 || { echo "husky did not set core.hooksPath"; exit 1; }

test: check
	$(NPM) run test

coverage:
	$(NPM) run coverage

format:
	$(NPM) run format

# Repo operations: a venv with a pinned interpreter, provisioned here rather than borrowed from the
# system. Idempotent — an existing venv with the right version is reused.
# uv itself is bootstrapped into .tools/bin when absent, so CI needs no extra install step.
tools:
	@command -v $(UV) >/dev/null 2>&1 || (mkdir -p $(TOOLS_BIN) && curl -LsSf https://astral.sh/uv/install.sh | UV_INSTALL_DIR=$(TOOLS_BIN) sh)
	@test -x $(TOOLS_PYTHON) || (command -v $(UV) >/dev/null 2>&1 && $(UV) venv --python $(PYTHON_VERSION) $(TOOLS_VENV) || $(TOOLS_BIN)/uv venv --python $(PYTHON_VERSION) $(TOOLS_VENV))
	@command -v $(UV) >/dev/null 2>&1 && $(UV) pip install --quiet --python $(TOOLS_PYTHON) pynacl || $(TOOLS_BIN)/uv pip install --quiet --python $(TOOLS_PYTHON) pynacl

secret-set: tools
	@$(TOOLS_PYTHON) tools/set_secret.py "$(REPO)" "$(SECRET)" "$(SECRET_VALUE_VAR)"

clean:
	rm -rf node_modules coverage .vitest dist .tools

# The single gate CI and the pre-push hook both run: no drift between them.
check: deps lint-check typecheck merge-markers
