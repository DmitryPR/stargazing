---
type: concept
title: View heading
status: approved
updated: 2026-11-08
---

A view heading is the compass bearing of the center of the Stellarium view. It is measured in degrees clockwise from true north: 0 is north, 90 is east, 180 is south, and 270 is west. It is not the observer's elevation in metres, and it is not the altitude of a selected object.

The connector returns that direction as an `altAz` vector from `GET /api/main/view`. In the vector, x points south, y points east, and z points to the zenith. For a vector `(x, y, z)` of length `r`:

- The south-based angle is `atan2(y, x)`, in radians.
- The compass heading is `(180 - degrees(atan2(y, x)))` wrapped into 0–360.
- The look altitude, how far above the horizon the view center sits, is `degrees(asin(z / r))`.

`POST /api/main/view` accepts `az` alone. In Stellarium 26.3 that number is the south-based angle in radians, the same angle `atan2(y, x)` returns. The OpenAPI text on this server calls `az` degrees. The plugin source passes `az` straight into `StelUtils::spheToRect`, which uses radians. This skill sends radians. Sending `az` without `alt` leaves the look altitude unchanged.

The returned vector is printed to about six significant digits. A later read can confirm the heading to 0.01°.
