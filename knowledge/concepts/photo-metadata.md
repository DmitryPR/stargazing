---
type: concept
title: Photo metadata
status: approved
updated: 2026-11-15
---

A photo record is the clock, place, and compass bearing stored in one photograph. It is not an observer place until a person accepts it, and it is not a sky time until a person accepts it.

The camera's `DateTimeOriginal` is the local clock time without a timezone. The GPS date and GPS time are the UTC instant. A heading whose reference is `T` is degrees clockwise from true north, the same sense as a view heading. A heading whose reference is `M` is magnetic. This record does not convert magnetic to true.

Latitude and longitude are degrees. Altitude is metres above sea level when the file marks it above sea level. A missing field stays missing. The photograph does not contain a place name, a look altitude, or the name of an object in the frame.

The read writes `output/read-photo/`. It does not change Stellarium and it does not write `knowledge/events/`.
