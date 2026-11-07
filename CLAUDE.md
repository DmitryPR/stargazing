# Rules

1. `CLAUDE.md` contains only short, permanent project rules.
2. Each skill describes one reusable job and points to the required knowledge and workflow.
3. Each knowledge file describes one concept, definition, product, or system.
4. Knowledge files use YAML metadata followed by readable Markdown.
5. Each workflow folder represents one ordered stage.
6. Every stage states its inputs, task, expected output, and review checks.
7. Generated files go into `output/`. They never replace the source knowledge.
8. A person reviews important outputs before the next stage begins.
9. Stellarium is controlled from the terminal through its Remote Control connector. Use `scripts/`. Do not add a client library.
10. A new run of a workflow replaces that workflow's files in `output/`. It does not edit `knowledge/`.
