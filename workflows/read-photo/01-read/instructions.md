# 01 — Read

## Inputs

- The path of one photograph.
- `knowledge/concepts/photo-metadata.md`.

## Task

Run:

```bash
bash scripts/photo-read.sh --photo <path>
```

This stage reads that file. It does not call Stellarium, and it does not look up a place name.

## Expected output

`output/read-photo/01-photo.md`

The file records the local clock time, the GPS instant, the latitude, longitude, altitude, compass bearing, heading reference, and lens notes that were present. A missing field is shown as missing.

## Review checks

This output is important. Stop after this stage.

- Show each field the file contained and each field it lacked.
- A magnetic heading stays magnetic. Do not pass it to `set-heading`.
- Do not move the observer, set the sky, or save an event until the person accepts the field they want to use.
