# 01 — Connect

## Inputs

- Stellarium is already open.
- The Remote Control connector server is started.
- Optional: `STELLARIUM_URL`, `STELLARIUM_PASSWORD`.

## Task

Run:

```bash
bash scripts/connect.sh
```

Read `knowledge/systems/remote-control-connector.md` only when the script fails, and tell the person how to start the server. Do not start Stellarium for them.

## Expected output

`output/point-sky/01-connect.md`

The file records `connected` or `failed`, the connector URL, and a short reading of place, local time, field of view, and the current selection.

## Review checks

- Continue to resolve when the script exits 0 and the file says `connected`.
- Stop when the script exits non-zero. This stage has no further command to send.
