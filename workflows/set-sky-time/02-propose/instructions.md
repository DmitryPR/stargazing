# 02 — Propose

## Inputs

- A successful `output/set-sky-time/01-current.md`.
- One of: a UTC clock time, a local clock time, or an event name.
- `knowledge/concepts/sky-time.md`.

## Task

Run one of:

```bash
bash scripts/time-propose.sh --utc "<ISO-8601>"
bash scripts/time-propose.sh --local "<ISO-8601>"
bash scripts/time-propose.sh --event "<name>"
```

Use `--local` when the person gave a time in the observer's timezone. Use `--utc` when they gave UTC or a `Z` instant. Use `--event` when they named an event. Read `knowledge/events/` for that name. Do not invent an instant and do not turn a bare calendar date into midnight.

This stage writes the proposal. It does not call the connector.

## Expected output

`output/set-sky-time/02-proposed.md`

The file records the current time beside the target instant, with `status: review`, `choose`, or `missing`.

## Review checks

This output is important. Stop after this stage.

- Show the current time and the target local time, UTC, and event title when there is one.
- Run apply only when the status is `review` and the person accepts that instant.
- When the status is `choose` or `missing`, stop and ask. Do not apply.
