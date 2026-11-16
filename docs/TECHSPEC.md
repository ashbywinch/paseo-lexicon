# TECHSPEC — paseo-lexicon

## Shape

One server-only entry, `index.server.ts`, registering a single hook. The logic lives in
`server/tag.ts` so it can be tested without a daemon.

```text
agent.turn.before  →  tagRepo(agent.cwd, signal)
                        ├── isRepository(cwd)?   .git or .lexicon present, else return false
                        ├── repoName(cwd)        strip a worktree hash prefix
                        └── POST /_tag           repo=<name>&path=<abs path>, 1.5 s ceiling
```

## Decisions

| Decision | Reason |
|---|---|
| `agent.turn.before`, not a selection event | no hook reports the client's selected workspace; a turn starting is the closest daemon-side signal, and its payload carries `cwd` |
| Notification hook, not a waiting one | Paseo does not wait for it, so tagging cannot slow a turn |
| Return `false` on any failure | a stopped shim must cost vocabulary, not dictation |
| Validate the path is a checkout | subagents and helpers run anywhere; an untrusted path would evict the user's repository from the shim window |
| No client entry | a client bundle would make every app version gate installation, for a plugin the app never calls |
| 1.5 s request ceiling combined with the hook signal | the hook's own ceiling is 30 s, long enough to pile up pending requests against a hung shim |
| Server-only tests over the real functions | the hook wiring is two lines; the behaviour worth testing is path validation and request shape |

## Shim contract

`POST /_tag` with form fields `repo` and `path`. The shim responses:

| Status | Meaning |
|---|---|
| 200 | stored; the repository joins the union until its window expires |
| anything else | logged, treated as failure, turn continues |

The shim unions every repository reported inside `LEXICON_WINDOW_HOURS` (default 12), freshest first,
then appends the shared list and truncates at the provider's 100-term cap.

## Failure behaviour

| Failure | Effect |
|---|---|
| shim down or refusing | one `console.error`, tag dropped, dictation uses the shared list |
| shim slow | request aborted at 1.5 s; no pending work accumulates |
| plugin reloaded while agents run | Paseo reopens sessions; turns continue |
| daemon restarted | the shim's window empties; the next turn repopulates it |

## Testing

`make test` runs `tsc --noEmit` then vitest. Coverage is gated in the test config, not in CI prose:
statements/lines/functions 80, branches 70. The tests use real temporary directories for
`isRepository` and a stubbed `fetch` for the request shape, so no network and no daemon are needed.

## Versioning

`package.json` holds the version; adoption is by directory or Git ref. `requirements.paseo` in
`paseo-plugin.json` is the compatibility contract the daemon enforces before loading.
