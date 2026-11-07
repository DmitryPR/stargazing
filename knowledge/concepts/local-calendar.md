---
type: concept
title: Local calendar
status: approved
updated: 2026-11-07
---

A local calendar is the list of upcoming sky events at one observer place. The place is the location Stellarium is using. Upcoming is measured from the computer's current UTC, not from the simulation time.

The window is 366 days unless the person asks for another length. An event is included when its `utc` is inside that window and it is visible at the place.

Each event is a file in `knowledge/events/`. It already has `type: event`, a title, and `utc`. The calendar also requires `visibility`.

`visibility: global` means the event is included at every place. `visibility: local` means the file also has `latitude`, `longitude`, and `radius_km`. The event is included when the place is within that radius, in kilometres.

An event with no `visibility` is left out. The calendar does not invent events, and it does not change the sky or the observer place.
