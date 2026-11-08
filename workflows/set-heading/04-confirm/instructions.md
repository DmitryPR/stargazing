# 04 — Confirm

## Inputs

- A successful `output/set-heading/03-apply.md`.
- The same `output/set-heading/02-proposed.md`.

## Task

Run:

```bash
bash scripts/heading-confirm.sh
```

This reads `GET /api/main/view` again and compares the compass heading with the accepted one. The match tolerance is 0.01°. It also checks that the look altitude stayed within 0.01°.

## Expected output

`output/set-heading/04-confirm.md`

The file records the heading Stellarium now reports and whether it matches the proposal.

## Review checks

Stop. The person checks Stellarium.

- Do not apply again to correct the heading unless the person asks for a new run.
- Do not copy this file into `knowledge/`.
