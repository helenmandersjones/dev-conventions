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
- **`AGENTS.md`** — shared agent orientation and mandatory convention-loading
  instructions. It is exposed under the native entry-point name used by each
  supported coding agent.
- **`scaffold/docs/tasks/`** — starter task tracker files copied into each
  project by `bootstrap.sh` (committed per project, not symlinked).

Human-facing product docs (`user-guide`, `technical-design`, `operations`)
live **in each app**, not in this repo, and are not part of the conventions
symlink.

## Application deployment automation

The shared deployment pattern is documented in
`docs/conventions/application-deployment-automation.md`. It favors
version-controlled Bash/Python scripts, thin Rundeck jobs, immutable artifact
and image identity, explicit dry-run/debug behavior, and real QA integration
over local cloud mocks. The `nbn-automate-application-deployment` skill applies the
pattern to end-to-end deployment automation tasks.

## Branch review and Jira workflow

In Codex, type `$` in the message box and select a skill from the autocomplete
list. Add the repository-specific instruction after the selected skill.

Review the current feature branch against its integration branch, then draft
deduplicated Jira issues from confirmed findings:

```text
$nbn-review-branch-to-jira Review the current branch against develop and draft Jira issues in project AI
```

The skill records the reviewed branch and commit, checks for likely duplicate
issues, and shows the proposed issue set before creating anything in Jira.
Approve the displayed set when ready.

Implement an explicit set of Jira review findings on the current feature
branch:

```text
$nbn-implement-jira-review-findings AI-1, AI-2, AI-3
```

Supply issue keys explicitly so the skill does not infer authorization from the
whole Jira backlog. It revalidates and implements each finding in sequence,
reviews each resulting diff, runs the required tests, and creates a separate
commit per accepted issue. Straightforward fixes are made directly in the
current task; a separate implementation agent is reserved for unusually broad
or high-risk work, or when explicitly requested. Pushing and merging remain
with the human. Each selected ticket moves to **In Progress** when its work
starts and to **Review** after its implementation, tests, review, and commit
pass, when those Jira workflow transitions are available. Add an override only
when the repository context is not sufficient, for example:

```text
$nbn-implement-jira-review-findings AI-12, AI-14 base: release/2.0
```

The two skills are deliberately separate, providing a review and approval
point between ticket creation and code changes:

```text
review branch -> inspect and approve Jira drafts -> implement selected issues -> human merges
```

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
- `<project>/CLAUDE.md            -> ../dev-conventions/AGENTS.md`
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
- More specific agent instruction files below the project root can add
  project- or directory-specific guidance where the coding agent supports
  hierarchical instructions.

## If you ever need to go fully self-contained

(e.g. open-sourcing one of the apps.) Replace each symlink with a real copy,
remove the `.gitignore` entries, and commit. Then keep the copy in sync from
this repo by hand or via a small sync script.
