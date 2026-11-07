---
type: concept
title: Sky time
status: approved
updated: 2026-11-07
---

A sky time is the single instant Stellarium is simulating. The connector reports that instant as local time, UTC, and a Julian day. The Julian day in the status is the UTC instant.

The change is `POST /api/main/time`. The form field `time` is the Julian day. The form field `timerate` is how many days the simulation advances each real second. This skill sends `timerate` as `0`, so the sky stays on the chosen instant.

A calendar date is a sky time only when it includes a clock time. A local clock time uses the observer timezone reported by the connector. A UTC clock time is absolute.

An event is a named sky time stored in one file under `knowledge/events/`. The front matter has `type: event`, a title, and `utc` as an ISO-8601 instant ending in `Z`. The body says what the event is. The skill uses that instant and does not invent one.
