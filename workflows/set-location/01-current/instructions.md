# 01 — Current location

## Inputs

- Stellarium is already open.
- The Remote Control connector server is started.
- Optional: `STELLARIUM_URL`, `STELLARIUM_PASSWORD`.

## Task

Run:

```bash
bash scripts/location-current.sh
```

This stage only reads. It does not change the observer.

Read `knowledge/systems/remote-control-connector.md` only when the script fails, and tell the person how to start the server. Do not start Stellarium for them.

## Expected output

`output/set-location/01-current.md`

The file records `connected` or `failed`, and the current name, latitude, longitude, altitude, planet, and region.

## Review checks

- Stop when the script exits non-zero.
- Stop and ask for a latitude and longitude when the person has not given both.
- Continue to propose when the script exits 0 and both coordinates are already known.
