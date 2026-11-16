# AGENTS.md — paseo-lexicon

A Paseo plugin with one job: tell the transcription shim which repository's dictation vocabulary
applies. Read this, then follow the link for the task.

## Quick start

- `make setup` — install dependencies and create `.env` from `.env.example`
- `make test` — typecheck then tests; the gate
- `make check` — lint and typecheck, what the pre-push hook runs
- `make tools` — the project's venv with a pinned Python; never use the system interpreter
- Never construct ad-hoc `npx` commands; everything goes through `make`.

## Where things live

| Task | Route to |
|---|---|
| What this plugin is for, and its acceptance | `docs/PRD.md` |
| How the hook and the shim contract work | `docs/TECHSPEC.md` |
| Phases and operations | `docs/PLAN.md` |
| Coding standard (project rules in the last section) | `docs/coding-standards.md` |
| Testing standard | `docs/testing-standards.md` |
| Documentation standard | `docs/writing-documentation.md` |
| Required doc set | `docs/documentation-structure.md` |
| Adding vocabulary to a repository or the shared list | `skill://dictation-vocabulary` (in `omp-config`) |

## Rules

- Never commit to main: branch, PR, protected main.
- Keep the plugin server-only. A client entry would require every connected app to match this
  plugin's version for no benefit; the hook needs nothing from the app.
- The hook must never throw on a shim failure. Dictation falling back to the shared list is the
  designed degradation; a failed turn is not.
- Real secrets live in the shell environment. `.env` is gitignored; `.env.example` documents names
  only.
