# PRD — paseo-lexicon

Status: shipped and installed. Owner: Ashby. Date: 2026-11-16.

## Problem

Dictation cannot name the repository it is about. Paseo's dictation request is produced by the
daemon, which has no working directory, and the request carries no workspace field. Meanwhile the
lexicon that fixes misheard jargon lives per repository in `.lexicon`.

Without context, the shim can only apply the shared list, so `Rightmove`, `TfL`, `LiteLLM` and every
other repository-specific name stay mangled.

## Users

One user: the developer, dictating into Paseo with roughly five repositories in flight at once.

## Requirements

| # | Requirement |
|---|---|
| R1 | Report the repository of an agent turn to the shim, with the repository's absolute path. |
| R2 | Never delay or fail an agent turn, even when the shim is down. |
| R3 | Report only real checkouts; a scratch directory must not displace a repository. |
| R4 | Support several active repositories: the shim receives every report and unions them. |
| R5 | Ship with no client entry, so a connected app's version never gates installation. |
| R6 | Bound each request so a hung shim cannot accumulate pending work. |

## Non-goals

- Reading vocabulary files. The shim owns that; this plugin only says which repository to read.
- Selecting *the* repository. Dictation cannot name one, and five concurrent repos make any single
  answer wrong.
- Capturing the workspace the user is looking at in the app. No hook exposes client selection, so a
  turn start is the signal used instead.

## Acceptance

| Check | Bar |
|---|---|
| Tag arrives | the shim logs `Tagged repo: <name>` after an agent turn |
| Vocabulary applies | dictating the `houses` fixture yields `Rightmove`, `TfL`, `floorplan` |
| Turn latency | unchanged; the hook is a notification and Paseo does not wait for it |
| Shim down | the turn completes, one error is logged, dictation uses the shared list |
| Tests | `make test` green, coverage floor met |

## Constraints

- Runs unsandboxed in the daemon's plugin subprocess, so the code must stay small and obvious.
- The daemon may be any supported version; `requirements.paseo` is `>=0.15.0` because the hook and
  the `background` field differ across releases.
