# 02 — Fetch

## Inputs

- A successful `output/fetch-events/01-window.md`.
- `knowledge/concepts/event-sources.md`.

## Task

Run:

```bash
bash scripts/events-fetch.sh
```

The script runs `scripts/scrapers/usno.sh` and `scripts/scrapers/imo.sh`, then writes the proposal from those records. It keeps a row as a proposed event only when the record has a UTC clock time.

This stage does not write `knowledge/events/` and does not change Stellarium.

## Expected output

`output/fetch-events/02-proposed.md`

Each scraper record is kept under `output/fetch-events/scraped/`. The proposal records each source as fetched or failed, the proposed instants in time order, the notes that have no clock time, and the other checks.

## Review checks

This output is important. Stop after this stage.

- Show the proposed instants, the rows with no clock time, and the other checks.
- An empty proposal is a finished fetch. Do not fill it with an invented time.
- Do not copy this file into `knowledge/`.
- Save an event file only after the person accepts that instant.
