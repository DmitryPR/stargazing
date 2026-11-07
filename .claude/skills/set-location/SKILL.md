---
name: set-location
description: >-
  Defines a custom observer location in Stellarium from the terminal, after
  reading the current location from the Remote Control connector. Use when
  the user asks to set, change, or define a location, latitude, longitude,
  altitude, or observer position in Stellarium, or to run the set-location
  workflow.
---

# Set a custom location

Read the current observer location first. Propose the custom coordinates second. Change Stellarium only after the person accepts that pair.

Run the stages in order. Use the scripts. Do not invent HTTP calls and do not add a client.

## Read first

- `knowledge/systems/stellarium.md`
- `knowledge/systems/remote-control-connector.md`
- `knowledge/concepts/custom-location.md`

## Workflow

Run `workflows/set-location/` in numeric order:

1. `01-current/instructions.md`
2. `02-propose/instructions.md`
3. `03-apply/instructions.md`
4. `04-confirm/instructions.md`

Stop when a stage says to stop. The proposal is important: do not apply until the person has seen the current location and accepted the custom one.

Do not invent coordinates. If the person has not given a latitude and longitude, stop after the current location and ask.

## Scripts

Execute these. Do not rewrite them for a single run.

- `bash scripts/location-current.sh`
- `bash scripts/location-propose.sh --latitude <degrees> --longitude <degrees> [--altitude <metres>] [--name <name>] [--region <region>] [--planet <planet>]`
- `bash scripts/location-apply.sh`
- `bash scripts/location-confirm.sh`

`location-apply.sh` reads the proposal file. Do not pass coordinates to it.

`STELLARIUM_URL` overrides the connector address. The default is `http://127.0.0.1:8090`. `STELLARIUM_PASSWORD` is sent as HTTP Basic auth with an empty username when the connector requires a password.
