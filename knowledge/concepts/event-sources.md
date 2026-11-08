---
type: concept
title: Event sources
status: approved
updated: 2026-11-08
---

An event source is a published page this repository is allowed to check. Stellarium's Remote Control connector is not an event source. It has no event list.

`fetch-events` checks each page with the matching script under `scripts/scrapers/`. Each script writes a record of that page. The fetch script reads those records and writes one proposal. A page script does not merge other sources, and it does not write `knowledge/events/`.

A row is a proposed instant only when the page gives one UTC clock time. A peak night, a local clock time, a weather note, or a Kp range stays a note. It is not given a UTC instant.

The page scripts and the pages they check:

- `usno` checks US Naval Observatory primary moon phases, `https://aa.usno.navy.mil/calculated/moon/phases?year=YYYY`. The page is one HTML table. A cell with a date and a clock time is one global instant.
- `imo` checks the International Meteor Organization shower calendar, `https://www.imo.net/calendar/`. The page is one HTML list of cards. A card gives a peak night and an active span.

The fetch writes `output/fetch-events/`. A person copies an accepted instant into an event file before `local-calendar` can list it.
