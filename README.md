# Star hackathon

The terminal drives Stellarium through its Remote Control connector. Rules are in `CLAUDE.md`. The comparison with Open Knowledge Format and Interpretable Context Methodology is in `SPEC.md`. This file is the index.

## Skills

| Skill | Job |
| --- | --- |
| [point-sky](.claude/skills/point-sky/SKILL.md) | Aim the view at one catalog object. |
| [set-location](.claude/skills/set-location/SKILL.md) | Read the observer place, then move it. |
| [set-sky-time](.claude/skills/set-sky-time/SKILL.md) | Read the simulation time, then set one instant from a clock time or an event file. |
| [local-calendar](.claude/skills/local-calendar/SKILL.md) | Read the place Stellarium is already using, then list upcoming events from `knowledge/events/`. |

Each skill points to its knowledge and its workflow. The stages stay in the skill.

## Handoff

Change the place with `set-location` before `local-calendar`. Show a listed instant with `set-sky-time`. `point-sky` stands on its own.

## Layout

- `knowledge/` holds one fact per file. Event instants live in `knowledge/events/`.
- `workflows/` holds the ordered stages for each skill.
- `scripts/` is what those stages run.
- `output/` holds the generated records of a run.
