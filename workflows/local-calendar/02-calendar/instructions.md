# 02 — Calendar

## Inputs

- A successful `output/local-calendar/01-place.md`.
- Event files in `knowledge/events/`.
- `knowledge/concepts/local-calendar.md`.
- Optional window length, only when the person asked for one.

## Task

Run:

```bash
bash scripts/calendar-list.sh
```

Or, when the person gave a length or asked for events that already happened:

```bash
bash scripts/calendar-list.sh --days <count>
bash scripts/calendar-list.sh --past
bash scripts/calendar-list.sh --past --days <count>
```

Read the event files. Do not add an event file unless the person asks. Do not look up new dates to fill an empty calendar.

## Expected output

`output/local-calendar/02-calendar.md`

The file records the place, the UTC window, whether the window runs backward, each included event in time order, and the events that were left out with the reason.

## Review checks

Stop. The person checks the calendar.

- An empty list is a finished calendar. Do not invent events to fill it.
- Do not copy this file into `knowledge/`.
- Do not change the simulation time unless the person asks to show one listed instant. That request uses `set-sky-time`.
