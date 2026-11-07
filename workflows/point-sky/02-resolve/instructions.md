# 02 — Resolve

## Inputs

- A successful `output/point-sky/01-connect.md`.
- The object name the person asked to see.
- `knowledge/concepts/sky-target.md`.

## Task

Run:

```bash
bash scripts/resolve.sh "<search>"
```

Use the person's words as the search string. Do not pick a different object to be helpful.

## Expected output

`output/point-sky/02-resolve.md`

The file records the search string, every catalog name the connector returned, and either one exact `target` or `status: review`.

## Review checks

This output is important. Stop after this stage.

- Show the person the exact catalog name, or the candidate list when there is no exact name.
- Accept a name only when it appears in that file.
- Run focus only after the person accepts one catalog name.
