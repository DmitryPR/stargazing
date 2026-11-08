# 02 — Fetch

## Inputs

- A successful `output/fetch-events/01-window.md`.
- `knowledge/concepts/event-sources.md`.

## Task

Run:

```bash
bash scripts/events-fetch.sh
```

The script downloads the named sources and writes the proposal. It keeps a row as a proposed event only when that row has a UTC clock time. Peak nights without a clock time are listed as incomplete.

This stage does not write `knowledge/events/` and does not change Stellarium.

## Expected output

`output/fetch-events/02-proposed.md`

The raw pages are kept under `output/fetch-events/raw/`. The proposal records each source as fetched or failed, the proposed instants in time order, and the incomplete rows.

## Review checks

This output is important. Stop after this stage.

- Show the proposed instants and the incomplete rows.
- An empty proposal is a finished fetch. Do not fill it with an invented time.
- Do not copy this file into `knowledge/`.
- Save an event file only after the person accepts that instant.
