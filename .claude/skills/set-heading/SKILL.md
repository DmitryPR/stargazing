---
name: set-heading
description: >-
  Sets the compass heading of the Stellarium view from the terminal, after
  reading the current view direction from the Remote Control connector. Use
  when the user asks to set, face, turn, or point the view to a heading,
  bearing, azimuth, or compass direction, or to run the set-heading workflow.
---

# Set the view heading

Read the current compass heading first. Propose one heading second. Change Stellarium only after the person accepts that pair.

The heading is degrees clockwise from true north. Do not invent a heading. Do not treat a compass letter as a second angle: `101° E` is heading 101, and the letter is only a check that it agrees with that number. If the letter and the number disagree, stop and ask.

This job does not move the observer and does not select an object. It leaves the look altitude unchanged.

Run the stages in order. Use the scripts. Do not invent HTTP calls and do not add a client.

## Read first

- `knowledge/systems/stellarium.md`
- `knowledge/systems/remote-control-connector.md`
- `knowledge/concepts/view-heading.md`

## Workflow

Run `workflows/set-heading/` in numeric order:

1. `01-current/instructions.md`
2. `02-propose/instructions.md`
3. `03-apply/instructions.md`
4. `04-confirm/instructions.md`

Stop when a stage says to stop. The proposal is important: do not apply until the person has seen the current heading and accepted the new one.

## Scripts

Execute these. Do not rewrite them for a single run.

- `bash scripts/heading-current.sh`
- `bash scripts/heading-propose.sh --heading <degrees>`
- `bash scripts/heading-apply.sh`
- `bash scripts/heading-confirm.sh`

Pass the compass degrees to propose. The script converts them to the radians the connector expects. `heading-apply.sh` reads the proposal file. Do not pass a heading to it.

`STELLARIUM_URL` overrides the connector address. The default is `http://127.0.0.1:8090`. `STELLARIUM_PASSWORD` is sent as HTTP Basic auth with an empty username when the connector requires a password.
