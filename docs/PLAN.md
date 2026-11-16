# PLAN — paseo-lexicon

## Phases

| Phase | Inputs | Outputs | Quality gate |
|---|---|---|---|
| 1. Hook | the shim's `/_tag` contract; `agent.turn.before` payload | `server/tag.ts`, one registration | `make test` green, coverage floor met |
| 2. Prove it | an agent turn in a tagged repo | `Tagged repo:` in the shim log; the `houses` fixture transcribes with its terms | shim log shows the tag; fixture yields `Rightmove`, `TfL`, `floorplan` |
| 3. Operate | a second active repo | the shim's window unions both | dictation in either repo keeps its own vocabulary |

Phase 1 is complete. Phase 2 is proven manually; phase 3 follows from the shim's union behaviour and
is exercised the first time two repositories are worked in during one window.

## Operations

| Event | Action |
|---|---|
| Install or upgrade | `paseo plugin install <dir or ref>`, then `paseo plugin ls` shows `running` |
| Watch it work | `journalctl --user -u cf-gateway-proxy | grep 'Tagged repo'` |
| Investigate a failure | `paseo plugin logs paseo-lexicon` |
| Roll back | `paseo plugin remove paseo-lexicon`; dictation keeps working with the shared list |

## Quality gates

- `make test` — typecheck plus tests; coverage thresholds live in `vitest.config.ts`.
- `make check` — lint and typecheck; the pre-push hook runs the same command.
- CI — `make setup`, `make lint-check`, `make test`, `make coverage`; coverage uploaded as an
  artifact.

## Known limits

- The plugin reports the *agent turn* repository, not the repository the user is viewing. With five
  repos mid-work the union covers all of them, which is the accepted trade.
- `agent.background` is absent from the 0.15 SDK types, so background helpers are not filtered; the
  checkout test is what keeps their directories out.
- A shim restart empties the window; the first dictation afterwards uses the shared list only.
