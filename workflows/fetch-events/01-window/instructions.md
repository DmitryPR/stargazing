# 01 — Window

## Inputs

- The computer clock.
- Optional window length, only when the person asked for one.
- `knowledge/concepts/event-sources.md`.

## Task

Run:

```bash
bash scripts/events-window.sh
```

Or, when the person gave a length:

```bash
bash scripts/events-window.sh --days <count>
```

This stage records the UTC window. It does not fetch a page and it does not read Stellarium.

## Expected output

`output/fetch-events/01-window.md`

The file records the start, the end, and the day count. A new run replaces the previous files for this workflow.

## Review checks

- Stop when the script exits non-zero.
- Continue to fetch when the script exits 0.
