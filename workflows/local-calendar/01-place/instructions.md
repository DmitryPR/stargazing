# 01 — Place

## Inputs

- Stellarium is already open.
- The Remote Control connector server is started.
- Optional: `STELLARIUM_URL`, `STELLARIUM_PASSWORD`.

## Task

Run:

```bash
bash scripts/calendar-place.sh
```

This stage only reads the observer place. It does not move Stellarium.

Read `knowledge/systems/remote-control-connector.md` only when the script fails, and tell the person how to start the server. Do not start Stellarium for them.

## Expected output

`output/local-calendar/01-place.md`

The file records `connected` or `failed`, and the place name, latitude, longitude, and timezone offset.

## Review checks

- Stop when the script exits non-zero.
- Stop and use `set-location` when this is not the place the person asked about.
- Continue to the calendar when the script exits 0 and the place is the one they want.
