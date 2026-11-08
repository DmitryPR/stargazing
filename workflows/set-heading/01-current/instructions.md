# 01 — Current heading

## Inputs

- Stellarium is already open.
- The Remote Control connector server is started.
- Optional: `STELLARIUM_URL`, `STELLARIUM_PASSWORD`.

## Task

Run:

```bash
bash scripts/heading-current.sh
```

This stage only reads. It does not turn the view.

Read `knowledge/systems/remote-control-connector.md` only when the script fails, and tell the person how to start the server. Do not start Stellarium for them.

## Expected output

`output/set-heading/01-current.md`

The file records `connected` or `failed`, the compass heading, the look altitude, and the `altAz` vector.

## Review checks

- Stop when the script exits non-zero.
- Stop and ask for a compass heading in degrees when the person has not given one.
- Continue to propose when the script exits 0 and the heading is already known.
