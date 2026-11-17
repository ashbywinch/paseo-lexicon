# paseo-lexicon

Tells the local transcription shim which repository's dictation vocabulary applies.

Dictation requests carry no repository: they come from the daemon, not from a process sitting in a
working directory. This plugin reports the repository of the agent whose turn just started, and the
shim unions every repository reported inside its window, so five repos in flight are all covered
rather than the last one winning.

## Quick start

```bash
make setup     # install dependencies
make test      # typecheck + tests
make check     # what the pre-push hook runs
```

## Repo operations

```bash
make tools       # the project's own venv, pinned interpreter, PyNaCl inside it
make secret-set  # set PASEO_LEXICON_API_KEY from CLOUDFLARE_AIGATEWAY_TOKEN
```

Tooling never comes from the system interpreter: `make tools` creates `.tools/venv` with a pinned
Python and installs into it. `.tools/` is gitignored, so `make clean` removes it and `make tools`
rebuilds it.

## What it does

One hook, `agent.turn.before`, posts `repo` and `path` to the shim's `/_tag` endpoint. It runs as a
notification, so it adds nothing to turn latency, and a failure is logged rather than thrown: a
stopped shim costs the repository's vocabulary, not the turn.

Only a real checkout is reported — a directory must contain `.git` or `.lexicon` — because a scratch
directory would otherwise evict the user's repository from the shim's window.

## Setup

The shim must listen on `http://127.0.0.1:9123` and accept `POST /_tag` with `repo` and `path` form
fields. Override the address with `LEXICON_SHIM_URL`. Vocabulary files and the proving procedure are
documented in the `dictation-vocabulary` skill in `omp-config`.

## Docs

| Doc | Holds |
|---|---|
| `docs/PRD.md` | the problem, users, requirements, acceptance |
| `docs/TECHSPEC.md` | the hook, the shim contract, failure behaviour |
| `docs/PLAN.md` | phases, quality gates, operations |
| `AGENTS.md` | routing for agents working in this repo |

## Versioning

`package.json` holds the version. Releases are tags `vMAJOR.MINOR.PATCH`; the plugin is installed
from a directory or a Git ref, so a tag is the unit of adoption.
