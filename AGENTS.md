# Agent guidance

This project follows shared conventions provided via the sibling
`dev-conventions/` repo, symlinked into:

- `.cursor/rules/` — operational rules (auto-loaded by Cursor).
- `.cursor/skills/` and `.agents/skills/` — shared agent skills (same
  `SKILL.md` folders; Cursor vs Codex discovery paths).
- `docs/conventions/` — long-form prose referenced from the rules.
- `AGENTS.md` (this file) — shared orientation for any agent.

## Where to look

- **Rules**: `.cursor/rules/` covers testing, service layer, multitenancy,
  HTMX patterns, TDD design-review loop, and more. Each `.mdc` file's
  frontmatter controls when it applies.
- **Conventions**: `docs/conventions/` for long-form details (e.g.
  `testing.md`, `service-layer.md`, `multitenancy.md`,
  `evolution-and-compatibility.md`).
- **Reference app**: `../grails-reference-app/` is the canonical minimal
  Grails implementation reference when that sibling repo exists. Use it for
  concrete examples of thin controllers, command objects, service transactions,
  DTO/input objects, central exception handling, full-page and HTMX validation,
  `components-plugin` GSP markup, URL mappings, and focused Spock tests.
- **Tasks** (per-project, not shared): `docs/tasks/` — `open/`, `done/`,
  `completed.md`, and `CURRENT_HANDOFF.md` when multi-slice work is active.
  Run `../dev-conventions/bootstrap.sh` on a new project to scaffold this
  folder if missing.
- **Project human-facing docs** (per-project, **not** symlinked from here):
  `docs/technical-design/`, `docs/user-guide/`, `docs/operations/`, plus
  `docs/dev-docs/` for implementation scratch. Open these when the task or
  user points at them; they are not always-on coding rules. See the app's
  `docs/README.md` when present.

## Editing rules vs. project code

- Project code → edit in this repo.
- Shared rules / skills / conventions / this file → edit in
  `../dev-conventions/` and commit there. The change is picked up
  automatically through the symlinks.
- Reference implementation patterns → read from `../grails-reference-app/`
  when present; do not copy its sample `Project` domain wholesale unless the
  target app genuinely needs that domain.

## Growing this file

This is intentionally a stub. Add shared guidance here as it emerges
(common workflows, agent etiquette, repo-shape orientation, etc.).
Project-specific guidance can live in a separate file at the project root
that complements this one.
