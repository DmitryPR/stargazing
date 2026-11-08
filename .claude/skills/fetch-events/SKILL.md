---
name: fetch-events
description: >-
  Fetches upcoming sky instants from the named published sources and writes a
  proposal. Use when the user asks to fetch, download, or look up upcoming
  events, moon phases, or meteor showers from a source, or to run the
  fetch-events workflow.
---

# Fetch upcoming events

Read the window first. Fetch the named sources second. Stop at the proposal.

A row becomes a proposed event only when the page gives a UTC clock time. A peak night without a clock time is listed and left incomplete. Do not invent a time, a rate, or a local moonset. Do not write `knowledge/events/`. Do not change the sky or the place.

Run the stages in order. Use the scripts. Do not invent HTTP calls and do not add a client library.

## Read first

- `knowledge/concepts/event-sources.md`
- `knowledge/concepts/local-calendar.md`
- `knowledge/concepts/sky-time.md`

## Workflow

Run `workflows/fetch-events/` in numeric order:

1. `01-window/instructions.md`
2. `02-fetch/instructions.md`

Stop when a stage says to stop. The proposal is important. Saving an accepted instant into `knowledge/events/` is a separate request. After that file exists, `local-calendar` can list it.

## Scripts

Execute these. Do not rewrite them for a single run.

- `bash scripts/events-window.sh`
- `bash scripts/events-window.sh --days <count>`
- `bash scripts/events-fetch.sh`

The window is 366 days unless the person asks for another length. `events-fetch.sh` reads the window file and the source pages. Do not pass URLs to it.
