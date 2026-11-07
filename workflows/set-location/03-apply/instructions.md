# 03 — Apply

## Inputs

- `output/set-location/02-proposed.md`.
- The person has accepted the custom location in that file.

## Task

Run apply only after that acceptance.

```bash
bash scripts/location-apply.sh
```

The script reads the proposal. Do not pass a different latitude or longitude. Do not send a second apply in the same run.

## Expected output

`output/set-location/03-apply.md`

The file records the custom location that was sent and the connector's reply.

## Review checks

- Continue to confirm when the script exits 0 and the reply is `ok`.
- Stop when the script exits non-zero. Report the reply. Leave the proposal unchanged.
