# 02 — Propose

## Inputs

- A successful `output/set-location/01-current.md`.
- The latitude and longitude the person asked for.
- Optional altitude in metres, name, region, and planet.
- `knowledge/concepts/custom-location.md`.

## Task

Run:

```bash
bash scripts/location-propose.sh --latitude <degrees> --longitude <degrees>
```

Add `--altitude`, `--name`, `--region`, or `--planet` only when the person supplied them. Do not look up a city and do not send `id`.

This stage writes the proposal. It does not call the connector.

## Expected output

`output/set-location/02-proposed.md`

The file records the current location beside the custom location, with `status: review`.

## Review checks

This output is important. Stop after this stage.

- Show the current location and the custom location.
- Run apply only after the person accepts that custom location.
- If they reject it, stop. Do not edit the current location.
