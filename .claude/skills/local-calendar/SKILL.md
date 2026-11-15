---
name: local-calendar
description: >-
  Builds a calendar of upcoming sky events for the observer location
  Stellarium is using. Use when the user asks for a local calendar, upcoming
  events, what is coming up at this place, or to run the local-calendar
  workflow.
---

# Local calendar

Read the observer place first. Then list events from `knowledge/events/` that are visible there. The window runs forward from the computer's current UTC. Pass `--past` when the person asks for events that already happened. Do not invent events, and do not change the sky or the place.

Published instants are fetched by `fetch-events`. That skill stops at a proposal. This skill lists a file only after a person has saved it under `knowledge/events/`.

Run the stages in order. Use the scripts. Do not invent HTTP calls and do not add a client.

## Read first

- `knowledge/systems/stellarium.md`
- `knowledge/systems/remote-control-connector.md`
- `knowledge/concepts/sky-time.md`
- `knowledge/concepts/local-calendar.md`

## Workflow

Run `workflows/local-calendar/` in numeric order:

1. `01-place/instructions.md`
2. `02-calendar/instructions.md`

Stop when a stage says to stop. The calendar is the result. Do not set the sky from it unless the person asks, and then use `set-sky-time`.

If the place should be somewhere else, stop and use `set-location` first. This skill only reads the place Stellarium is already using.

The window is 366 days. Pass `--days` only when the person asks for a different length.

## Scripts

Execute these. Do not rewrite them for a single run.

- `bash scripts/calendar-place.sh`
- `bash scripts/calendar-list.sh`
- `bash scripts/calendar-list.sh --days <count>`
- `bash scripts/calendar-list.sh --past`
- `bash scripts/calendar-list.sh --past --days <count>`

`STELLARIUM_URL` overrides the connector address. The default is `http://127.0.0.1:8090`. `STELLARIUM_PASSWORD` is sent as HTTP Basic auth with an empty username when the connector requires a password.
