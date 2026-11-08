# 02 — Propose

## Inputs

- A successful `output/set-heading/01-current.md`.
- The compass heading in degrees, clockwise from true north.
- `knowledge/concepts/view-heading.md`.

## Task

Run:

```bash
bash scripts/heading-propose.sh --heading <degrees>
```

Pass the number of degrees. Convert a degrees-minutes-seconds bearing to decimal degrees first, and keep the full precision of that conversion. Do not round to the nearest degree. A compass letter is not a heading by itself.

This stage writes the proposal. It does not call the connector.

## Expected output

`output/set-heading/02-proposed.md`

The file records the current heading beside the target heading, the radians that would be sent, and `status: review`.

## Review checks

This output is important. Stop after this stage.

- Show the current heading and the target heading in degrees, with the look altitude that will stay.
- Run apply only after the person accepts that heading.
- If they reject it, stop. Do not turn the view.
