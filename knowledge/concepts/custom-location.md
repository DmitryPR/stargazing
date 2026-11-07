---
type: concept
title: Custom location
status: approved
updated: 2026-11-07
---

A custom location is an observer position defined by coordinates. It is not a stored city id.

It has a latitude and longitude in degrees, an altitude in metres, a name, a planet, and a region. Latitude runs from -90 to 90. Longitude runs from -180 to 180.

Stellarium is already standing on a current location. That current location is read from `GET /api/main/status` before a custom location is proposed. The custom location replaces it only after the person accepts the change.

The change is `POST /api/location/setlocationfields`. The form fields are `latitude`, `longitude`, `altitude`, `name`, `region`, and `planet`. Do not send `id`. An id selects a stored place and ignores the other fields.
