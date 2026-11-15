---
name: read-photo
description: >-
  Reads the clock, GPS place, and compass bearing from one photograph. Use
  when the user asks to read a photo, its EXIF or GPS metadata, or the time,
  place, or direction a picture was taken, or to run the read-photo workflow.
---

# Read one photograph

Read one image file. Write the clock, place, and compass bearing that the file itself contains. Stop at that record.

Do not invent a missing time, coordinate, altitude, or heading. Do not turn a magnetic heading into a true heading. Do not name the place and do not name an object in the frame. Do not change Stellarium and do not write `knowledge/events/`.

Run the stage in `workflows/read-photo/`. Use the script. The metadata is read with Swift through ImageIO. Do not add a client library.

## Read first

- `knowledge/concepts/photo-metadata.md`
- `knowledge/concepts/custom-location.md`
- `knowledge/concepts/sky-time.md`
- `knowledge/concepts/view-heading.md`

## Workflow

1. `workflows/read-photo/01-read/instructions.md`

Stop at the record. After the person accepts it, `set-location`, `set-sky-time`, and `set-heading` can use a field that the record actually contains. A true heading is the only heading those skills can take from this record.

## Script

Execute this. Do not rewrite it for a single run.

```bash
bash scripts/photo-read.sh --photo <path>
```

A new run replaces `output/read-photo/`.
