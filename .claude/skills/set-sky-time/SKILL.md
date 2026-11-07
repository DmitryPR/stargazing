---
name: set-sky-time
description: >-
  Sets the Stellarium sky to one instant from the terminal, after reading the
  current simulation time from the Remote Control connector. The instant is a
  clock time or a named event in knowledge/events. Use when the user asks to
  set the date, time, or sky to a moment or an event in Stellarium, or to run
  the set-sky-time workflow.
---

# Set the sky time

Read the current simulation time first. Propose one instant second. Change Stellarium only after the person accepts that pair.

The instant comes from a clock time or from one event file. Do not invent a date, a clock time, or an event.

Run the stages in order. Use the scripts. Do not invent HTTP calls and do not add a client.

## Read first

- `knowledge/systems/stellarium.md`
- `knowledge/systems/remote-control-connector.md`
- `knowledge/concepts/sky-time.md`

## Workflow

Run `workflows/set-sky-time/` in numeric order:

1. `01-current/instructions.md`
2. `02-propose/instructions.md`
3. `03-apply/instructions.md`
4. `04-confirm/instructions.md`

Stop when a stage says to stop. The proposal is important: do not apply until the person has seen the current time and accepted the instant.

A clock time needs both a date and a time of day. If the person names an event, use the matching file in `knowledge/events/`. If none matches, stop and ask. Do not write an event file unless the person asks.

## Scripts

Execute these. Do not rewrite them for a single run.

- `bash scripts/time-current.sh`
- `bash scripts/time-propose.sh --utc "<ISO-8601>"`
- `bash scripts/time-propose.sh --local "<ISO-8601>"`
- `bash scripts/time-propose.sh --event "<name>"`
- `bash scripts/time-apply.sh`
- `bash scripts/time-confirm.sh`

Pass only one of `--utc`, `--local`, or `--event`. `time-apply.sh` reads the proposal file. Do not pass a time to it.

`STELLARIUM_URL` overrides the connector address. The default is `http://127.0.0.1:8090`. `STELLARIUM_PASSWORD` is sent as HTTP Basic auth with an empty username when the connector requires a password.
