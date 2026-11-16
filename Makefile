SHELL := /bin/bash
.SHELLFLAGS := -eu -o pipefail -c

NODE := node
NPM := npm

.PHONY: help setup deps lint lint-check typecheck test coverage format clean check

help:
	@echo "paseo-lexicon"
	@echo "  make setup      install dependencies"
	@echo "  make lint       report lint findings"
	@echo "  make typecheck  tsc --noEmit"
	@echo "  make test       typecheck + tests (the gate)"
	@echo "  make coverage   tests with a clover report in coverage/"
	@echo "  make format     rewrite formatting in place"
	@echo "  make check      lint + typecheck, what pre-push runs"
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

clean:
	rm -rf node_modules coverage .vitest dist

# The single gate CI and the pre-push hook both run: no drift between them.
check: lint-check typecheck
