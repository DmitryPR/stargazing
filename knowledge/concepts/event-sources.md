---
type: concept
title: Event sources
status: approved
updated: 2026-11-08
---

An event source is a published page this repository is allowed to fetch for sky instants. Stellarium's Remote Control connector is not an event source. It has no event list.

Two sources are named:

- US Naval Observatory primary moon phases, `https://aa.usno.navy.mil/calculated/moon/phases?year=YYYY`. Each cell that contains a date and a clock time is one global instant.
- International Meteor Organization shower calendar, `https://www.imo.net/calendar/`. A card gives a peak night and an active span. That page does not give the maximum as a UTC clock time.

A fetched row is a proposed event only when it has one UTC instant. A peak night without a clock time stays on the proposal as incomplete. It is not an event file and it is not given a midnight time.

The fetch writes `output/fetch-events/`. It does not write `knowledge/events/`. A person copies an accepted instant into an event file before `local-calendar` can list it.
