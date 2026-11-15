---
type: concept
title: Local calendar
status: approved
updated: 2026-11-15
---

A local calendar is the list of sky events at one observer place. The place is the location Stellarium is using. The clock for the window is the computer's current UTC, not the simulation time.

The window is 366 days unless the person asks for another length. By default it runs forward from now. When the person asks for past events, the same day count runs backward from now. An event is included when its `utc` is inside that window and it is visible at the place.

Each event is a file in `knowledge/events/`. It already has `type: event`, a title, and `utc`. The calendar also requires `visibility`.

`visibility: global` means the event is included at every place. `visibility: local` means the file also has `latitude`, `longitude`, and `radius_km`. The event is included when the place is within that radius, in kilometres.

An event with no `visibility` is left out. The calendar does not invent events, and it does not change the sky or the observer place.
