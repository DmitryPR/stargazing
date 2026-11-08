# Specification

Star-hackathon is an ICM-inspired workflow workspace with an OKF-shaped knowledge layer. It drives Stellarium from the terminal. This file records that comparison. It is not a conformance claim for either specification.

Operating rules remain in `CLAUDE.md`. The skill index remains in `README.md`.

## What this repository does

Durable facts live in `knowledge/`. One file describes one concept, system, or event. Each file is Markdown with YAML front matter.

A skill names one job and points at the knowledge and workflow for that job. A workflow is a numbered sequence of stages under `workflows/`. Each stage has an `instructions.md` that states its inputs, task, expected output, and review checks.

Shell scripts in `scripts/` perform the mechanical calls to Stellarium's Remote Control connector. A run writes its records under `output/<workflow>/`. A new run replaces that workflow's output files. It does not edit `knowledge/`.

A person reviews an important output before the next stage changes the sky or the observer place. Some early stages continue when their check passes, such as a successful connection.

## Open Knowledge Format

Checked against the Open Knowledge Format specification: [SPEC.md](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/main/SPEC.md).

An OKF concept is a UTF-8 Markdown file with YAML front matter and a Markdown body. The only required front-matter field is `type`. `title` and `description` are recommended. Lifecycle `status`, when used, is `draft`, `stable`, or `deprecated`.

The knowledge files here include `type` and a Markdown body, so they meet that minimum. They also set `title`, `status: approved`, and `updated`. `approved` is not an OKF lifecycle status. There is no `description`, no `index.md`, and no trust or provenance block. `concepts/` and `systems/` are this repository's grouping.

OKF does not define skills, workflows, scripts, or `output/`.

## Interpretable Context Methodology

Checked against the preprint [Interpretable Context Methodology](https://arxiv.org/abs/2603.16021) (Van Clief and McDermott, 2026) and its stage-contract description.

ICM uses one agent, numbered stage folders, and a stage contract of inputs, process, and outputs. Local scripts do mechanical work. A person can review the output before the next stage reads it. The contract file in that method is `CONTEXT.md`. Stable reference material and this run's working files are distinguished in the inputs.

This repository follows that idea. The differences are:

- The stage file is `instructions.md`, with Task and Review checks, rather than `CONTEXT.md` with Process.
- There is no root routing `CONTEXT.md`. Skills in `.claude/skills/` do that routing.
- A stage that passes its check may continue without a person stopping.
- Stage outputs share `output/<workflow>/` instead of a folder inside each stage.
- Inputs name files. They are not labeled as stable reference versus this run's working files.

## Sources

- Open Knowledge Format, [SPEC.md](https://github.com/GoogleCloudPlatform/open-knowledge-format/blob/main/SPEC.md), read 2026-11-08.
- Van Clief and McDermott, Interpretable Context Methodology, [arXiv:2603.16021](https://arxiv.org/abs/2603.16021), preprint, read 2026-11-08.
