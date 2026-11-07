# 04 — Confirm

## Inputs

- A successful `output/set-location/03-apply.md`.
- The same `output/set-location/02-proposed.md`.

## Task

Run:

```bash
bash scripts/location-confirm.sh
```

This reads `GET /api/main/status` again and compares it with the accepted custom location.

## Expected output

`output/set-location/04-confirm.md`

The file records the location Stellarium now reports and whether it matches the proposal.

## Review checks

Stop. The person checks Stellarium.

- Do not apply again to correct the place unless the person asks for a new run.
- Do not copy this file into `knowledge/`.
