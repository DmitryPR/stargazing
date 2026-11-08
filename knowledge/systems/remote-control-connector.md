---
type: system
title: Remote Control connector
status: approved
updated: 2026-11-08
---

The Remote Control plugin is Stellarium's HTTP connector. In Stellarium, enable the plugin, restart if it asks, then start the server from the plugin's configure dialog. The default address is `http://127.0.0.1:8090`.

The point-sky scripts call these operations:

- `GET /api/main/status` returns the current place, time, field of view, and an HTML description of the selected object.
- `GET /api/objects/find?str=` returns a JSON array of catalog names that match the search string. A match in that list is not yet a sky target.
- `POST /api/main/focus` selects an object. The body is form fields: `target` is the catalog name, and `mode` is `center`, `zoom`, or `mark`. `center` moves the object to the middle of the view. `zoom` also zooms in. `mark` selects it and leaves the view where it is.

The set-heading scripts call `GET /api/main/view` and `POST /api/main/view`. The compass conversion for that call is in `knowledge/concepts/view-heading.md`.

A successful POST often returns the text `ok`. A failure body starts with `error:`.

If the server has a password, send HTTP Basic auth with an empty username and that password. The interactive API index, when the server is up, is `http://127.0.0.1:8090/docs/index.html`.
