---
type: criteria
title: Read-photo check
status: approved
updated: 2026-11-15
---

These criteria are fixed before a photograph is judged. A pass means the record is ready for a person. It does not accept the place, the instant, or the heading.

The script `scripts/check-read-photo.sh` decides these. They are deterministic.

1. The record has `status: review`.
2. A field that the file did not contain is empty. The check does not fill it.
3. `heading_ref` of `T` is a true heading. `heading_ref` of `M` is magnetic and fails this check. The recorded degrees stay the degrees from the file.
4. When the caller supplies an expected true reading, the UTC instant, latitude, longitude, and heading match that reading.

A person judges whether the numbers match the photograph they can open. The script does not make that judgment.

No expected reading is stored in this file. The test script holds the fixture readings outside the skill.
