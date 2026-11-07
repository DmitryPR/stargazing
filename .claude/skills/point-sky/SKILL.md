---
name: point-sky
description: >-
  Points the Stellarium desktop app at one named sky object from the terminal
  by calling the Remote Control connector. Use when the user asks to show,
  focus, center, zoom to, or go to an object in Stellarium, or to run the
  point-sky workflow.
---

# Point the sky

Point Stellarium at one catalog object. Run the stages in order. Use the scripts. Do not invent HTTP calls and do not add a client.

## Read first

- `knowledge/systems/stellarium.md`
- `knowledge/systems/remote-control-connector.md`
- `knowledge/concepts/sky-target.md`

## Workflow

Run `workflows/point-sky/` in numeric order:

1. `01-connect/instructions.md`
2. `02-resolve/instructions.md`
3. `03-focus/instructions.md`
4. `04-confirm/instructions.md`

Stop when a stage says to stop. The resolve output is important: do not focus until the person accepts one catalog name.

## Scripts

Execute these. Do not rewrite them for a single run.

- `bash scripts/connect.sh`
- `bash scripts/resolve.sh "<search>"`
- `bash scripts/focus.sh "<catalog name>" [center|zoom|mark]`
- `bash scripts/confirm.sh "<catalog name>"`

Default focus mode is `center`. Use `zoom` or `mark` only when the person asks.

`STELLARIUM_URL` overrides the connector address. The default is `http://127.0.0.1:8090`. `STELLARIUM_PASSWORD` is sent as HTTP Basic auth with an empty username when the connector requires a password.
