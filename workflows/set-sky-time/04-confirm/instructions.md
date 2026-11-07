# 04 — Confirm

## Inputs

- A successful `output/set-sky-time/03-apply.md`.
- The same `output/set-sky-time/02-proposed.md`.

## Task

Run:

```bash
bash scripts/time-confirm.sh
```

This reads `GET /api/main/status` again and compares the simulation time with the accepted instant.

## Expected output

`output/set-sky-time/04-confirm.md`

The file records the time Stellarium now reports and whether it matches the proposal.

## Review checks

Stop. The person checks Stellarium.

- Do not apply again to correct the time unless the person asks for a new run.
- Do not copy this file into `knowledge/`.
