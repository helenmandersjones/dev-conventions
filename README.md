# dev-conventions

Shared development conventions and AI agent rules 

## Onboarding (new project or fresh clone)

```bash
# from the parent workspace dir, with project already cloned:
./dev-conventions/bootstrap.sh ./my-new-app
```

The script creates the shared symlinks (including skills for both Cursor and
Codex), scaffolds `docs/tasks/` when missing (files are copied into the project
and should be committed there), and prints the `.gitignore` lines to add. It's
idempotent: re-running leaves existing symlinks and task files alone; only
missing scaffold files are added under `docs/tasks/`.

For Grails apps, keep `grails-reference-app/` cloned next to the app and this
repo when possible. Agents use it as the canonical minimal implementation
reference for new feature slices.


## Further Info:

## What's here

- **`cursor/rules/`** — `.mdc` rule files read by [Cursor](https://cursor.sh)
  from each project's `.cursor/rules/` directory.
- **`skills/`** — Agent Skills (`SKILL.md` folders). Shared across agents via
  project symlinks: `.cursor/skills` (Cursor) and `.agents/skills` (Codex).
- **`docs/conventions/`** — long-form prose conventions referenced from rules
  and from in-repo code/docs (e.g. `docs/conventions/testing.md`,
  `multitenancy.md`).
- **`AGENTS.md`** — generic orientation surfaced to Cursor / Codex / Claude
  / etc. via a symlink at each project root.
- **`scaffold/docs/tasks/`** — starter task tracker files copied into each
  project by `bootstrap.sh` (committed per project, not symlinked).

Human-facing product docs (`user-guide`, `technical-design`, `operations`)
live **in each app**, not in this repo, and are not part of the conventions
symlink.

## How projects use this

This repo is **not** a dependency in any build sense. Each app expects to find
`dev-conventions/` cloned **next to it** as a sibling directory:

```
GRAILS/
  dev-conventions/         <-- this repo
  grails-reference-app/     <-- canonical implementation reference
  my-new-app/
  planeout/
  ...
```

Each project gets the shared content via **relative symlinks** at:

- `<project>/AGENTS.md            -> ../dev-conventions/AGENTS.md`
- `<project>/.cursor/rules        -> ../../dev-conventions/cursor/rules`
- `<project>/.cursor/skills       -> ../../dev-conventions/skills`
- `<project>/.agents/skills       -> ../../dev-conventions/skills`
- `<project>/docs/conventions     -> ../../dev-conventions/docs/conventions`

The symlinks are `.gitignore`d in each project. Cloning a project alone is
not enough — you also need to clone `dev-conventions` next to it and run
`bootstrap.sh`.

When `../grails-reference-app/` exists beside an app, agents should start at
`../grails-reference-app/docs/reference/README.md` for concrete examples of
thin controllers, command objects, typed service inputs, central exception
handling, full-page and HTMX validation, `components-plugin` markup, URL
mappings, and focused Spock tests.


## Updating conventions

Edit files here, commit, push. Each app picks up the change immediately
because it reads through the symlink — no per-app sync needed.

## What stays in each project

- `docs/tasks/` (open/done/handoffs/CURRENT_HANDOFF.md) — task tracking is
  per-project. `bootstrap.sh` copies the initial layout from
  `dev-conventions/scaffold/docs/tasks/` when the folder does not exist yet.
- `docs/dev-doc/`, PRDs, implementation plans — project-specific design docs.
- `AGENTS.md` (if present) at the project root — project-specific agent
  guidance can layer on top of the shared rules here.

## If you ever need to go fully self-contained

(e.g. open-sourcing one of the apps.) Replace each symlink with a real copy,
remove the `.gitignore` entries, and commit. Then keep the copy in sync from
this repo by hand or via a small sync script.
