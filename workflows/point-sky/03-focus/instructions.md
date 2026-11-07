# 03 — Focus

## Inputs

- `output/point-sky/02-resolve.md`.
- One catalog name the person accepted from that file.
- Optional mode: `center` (default), `zoom`, or `mark`.

## Task

Run focus only after the person has accepted the name.

```bash
bash scripts/focus.sh "<catalog name>"
bash scripts/focus.sh "<catalog name>" zoom
bash scripts/focus.sh "<catalog name>" mark
```

Do not change the accepted name. Do not send a second focus in the same run.

## Expected output

`output/point-sky/03-focus.md`

The file records the catalog name, the mode, and the connector's reply.

## Review checks

- Continue to confirm when the script exits 0 and the reply is `ok`.
- Stop when the script exits non-zero. Report the reply. Do not guess another name.
