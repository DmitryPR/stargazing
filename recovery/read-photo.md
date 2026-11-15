# Read-photo recovery

Use this when the photograph cannot be read, or when the mechanical check fails.

## Unreadable file

- Trigger: `scripts/photo-read.sh` exits 1.
- Evidence: the script message. No photo record is written.
- Allowed action: ask the person for a path. Do not invent metadata.
- Attempts: 1 ask, then stop.
- Budget: no measured time or money limit. Stop after the ask. This budget is a pilot assumption.
- Checkpoint: the run state file. Earlier runs in `runs/read-photo/` stay where they are.
- Verification: a new path has to exist before a new attempt.
- Escalation: the person who asked for the read, when the path is still missing after the ask.

## Magnetic heading

- Trigger: `scripts/check-read-photo.sh` finds `heading_ref` of `M`.
- Evidence: the photo record in the run folder.
- Allowed action: leave the degrees as recorded. Do not convert magnetic to true. Do not pass the heading to `set-heading`.
- Attempts: none. A conversion is not a retry.
- Budget: no measured time or money limit. Stop at the failed check.
- Checkpoint: the failed record stays in the run folder. A later read may replace `output/read-photo/` and must not delete this run.
- Verification: the stored `heading_ref` is still `M` and the degrees are unchanged.
- Escalation: the person who asked for the read.

## Stellarium

This workflow does not change Stellarium. It has no sky rollback. A later acceptance uses `set-location`, `set-sky-time`, or `set-heading` for one field the person names.
