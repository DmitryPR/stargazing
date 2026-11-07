# 01 — Current time

## Inputs

- Stellarium is already open.
- The Remote Control connector server is started.
- Optional: `STELLARIUM_URL`, `STELLARIUM_PASSWORD`.

## Task

Run:

```bash
bash scripts/time-current.sh
```

This stage only reads. It does not change the simulation time.

Read `knowledge/systems/remote-control-connector.md` only when the script fails, and tell the person how to start the server. Do not start Stellarium for them.

## Expected output

`output/set-sky-time/01-current.md`

The file records `connected` or `failed`, and the current local time, UTC, Julian day, timezone, and timerate.

## Review checks

- Stop when the script exits non-zero.
- Stop and ask for a clock time or an event name when the person has not given either.
- Continue to propose when the script exits 0 and the target instant is already known.
