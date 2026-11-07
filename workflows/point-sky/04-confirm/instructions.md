# 04 — Confirm

## Inputs

- A successful `output/point-sky/03-focus.md`.
- The same accepted catalog name.

## Task

Run:

```bash
bash scripts/confirm.sh "<catalog name>"
```

Read the Stellarium window only if the person is looking at it with you. The connector status is the record of what the app selected.

## Expected output

`output/point-sky/04-confirm.md`

The file records the name Stellarium reports as selected, whether that name is the accepted target, and altitude, azimuth, and field of view.

## Review checks

Stop. The person looks at Stellarium and accepts or rejects the result.

- Do not focus again to correct the view unless the person asks for a new run.
- Do not copy this file into `knowledge/`.
