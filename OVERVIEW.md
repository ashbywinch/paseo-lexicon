# paseo-lexicon

Tells the local transcription shim which repository's dictation vocabulary applies.

Dictation requests carry no repository: they come from the daemon, not from a process sitting in a
working directory. This plugin reports the repository of the agent whose turn just started, which is
the workspace being worked in when dictation follows. The shim then attaches that repository's
`.lexicon` terms, plus the shared list, to the transcription request.

With no report yet, the shim uses the shared list alone, so a repository never leaks vocabulary into
an unrelated dictation.

Setup: the shim must listen on `http://127.0.0.1:9123` and accept `POST /_tag` with `repo` and
`path` form fields. Override the address with `LEXICON_SHIM_URL`. Vocabulary files are documented in
the `dictation-vocabulary` skill.
