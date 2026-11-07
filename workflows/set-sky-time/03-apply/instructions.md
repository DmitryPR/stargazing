# 03 — Apply

## Inputs

- `output/set-sky-time/02-proposed.md` with `status: review`.
- The person has accepted the instant in that file.

## Task

Run apply only after that acceptance.

```bash
bash scripts/time-apply.sh
```

The script reads the proposal. Do not pass a different time. Do not send a second apply in the same run.

## Expected output

`output/set-sky-time/03-apply.md`

The file records the Julian day and timerate that were sent, and the connector's reply.

## Review checks

- Continue to confirm when the script exits 0.
- Stop when the script exits non-zero. Report the reply. Leave the proposal unchanged.
