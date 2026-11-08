# Task tracker (lightweight Kanban-style docs)

This folder holds **one Markdown file per task**, plus a **completed-task index**. The goal is a cheap, version-controlled substitute for sticky notes or a board: no extra tooling, everything lives in git next to the code.

## Would this help an AI assistant?

**Often yes**, if you keep it current. A short `completed.md` gives immediate context on what already shipped; open task files clarify intent and acceptance criteria without re-scanning the whole repo. It works best when titles are specific and each task file links to the main code or PR.

**Limits:** It is only as good as the last update. Large backlogs still need prioritisation outside these files.

---

## Resume in a new chat (multi-slice / TDD tasks)

When you are **actively working through a task** that uses slice handoffs (`open/<slug>-handoff.md`), keep a single pointer up to date:

1. Edit **[`CURRENT_HANDOFF.md`](CURRENT_HANDOFF.md)** so the **Handoff** and **Task** links point at the `open/*.md` files you care about now.
2. In a **new chat**, either:
   - **@** mention [`CURRENT_HANDOFF.md`](CURRENT_HANDOFF.md), or  
   - Type a short instruction, for example: **`Resume task handoff`** or **`Read docs/tasks/CURRENT_HANDOFF.md and continue`**, or  
   - Use the project skill **`nbn-resume-task-handoff`** (see [`.cursor/skills/nbn-resume-task-handoff/SKILL.md`](../../.cursor/skills/nbn-resume-task-handoff/SKILL.md)).

The assistant should read **`CURRENT_HANDOFF.md` first**, then the linked **handoff** file (latest slice / next slice), then the **task** file.

**On each completed slice:** update the real handoff file (`open/<slug>-handoff.md`) per [Slice completion handoff](#how-to-create-a-new-task) below. You do **not** need to touch `CURRENT_HANDOFF.md` on every slice unless you switched tasks.

**When the whole task is finished:** move the task (and optional handoff) to `done/`, update `completed.md`, then **clear or repoint** `CURRENT_HANDOFF.md`.

---

## How to create a new task

1. **Copy the template**  
   Duplicate [`TEMPLATE.md`](TEMPLATE.md) into the right subfolder:
   - [`open/`](open/) — not started or in progress  
   - [`done/`](done/) — finished (move the file here when you close the task)

2. **Name the file**  
   Use a short **kebab-case** slug and date prefix if you like collisions avoided:  
   `YYYY-MM-DD-short-title.md` e.g. `2026-04-03-add-org-export.md`

3. **Fill in the template**  
   - **Title** — one line, meaningful in `completed.md`  
   - **Status** — `open` | `in_progress` | `done`  
   - **Summary** — what and why (2–5 sentences)  
   - **Acceptance criteria** — checkboxes you can tick  
   - **Notes / links** — PRs, commits, paths, follow-ups

4. **When the task is done**  
   - Move the file from `open/` to `done/` (or create it directly in `done/` if it was small).  
   - Set **Status** to `done` and tick acceptance criteria.  
   - Add one line to [`completed.md`](completed.md): short title + link to the task file.

5. **Slice completion handoff (TDD / multi-slice tasks)**  
   When a **slice** reaches **GREEN**, do not stop yet. Complete the full loop first:
   - **Design review (no edits):** list issues against project patterns (responsibility placement, over-abstraction, style deviations, overly defensive code).
   - **Refactor:** improve structure without behaviour change.
   - **Verify:** rerun slice tests (and any impacted related tests).
   Only then append or update the **handoff file** so the next chat or developer can continue without re-reading the whole thread:
   - **Path:** `docs/tasks/open/<same-slug-as-task>-handoff.md` (one file per task; **append** new slice sections or use one section per slice with date).
   - **Template:** copy structure from [`HANDOFF-TEMPLATE.md`](HANDOFF-TEMPLATE.md) — include RED, GREEN, DESIGN REVIEW, REFACTOR, VERIFY, notes, and **next slice** hint.
   - **Link:** add a line under the task file’s **Links** section pointing to the handoff file.
   - **Optional:** when the whole task is done, you may move the handoff next to the task under `done/` or fold key bullets into the task file before archive.

6. **Optional**  
   If you abandon a task, move it to `open/` with status note, or add a **Cancelled** section in the file and still list it in `completed.md` as “Cancelled: …” if you want history.

---

## Folder layout

| Path | Purpose |
|------|---------|
| `CURRENT_HANDOFF.md` | Pointer to the active task + handoff for new-chat resume (optional; edit when switching focus) |
| `README.md` | This file — conventions and instructions |
| `TEMPLATE.md` | Copy for new tasks |
| `HANDOFF-TEMPLATE.md` | Template for per-slice completion summaries (after GREEN) |
| `completed.md` | Index of finished work (short titles + links) |
| `open/` | Active or future tasks |
| `open/*-handoff.md` | Slice handoffs for in-progress tasks (link from task file) |
| `done/` | One `.md` file per completed task |

---

## Conventions

- Prefer **links to code** (e.g. `grails-app/controllers/...`) over vague descriptions.
- Keep each task file **under ~1–2 screens**; split epics into multiple tasks.
- **Commit** task updates in the same commit as the code when possible, so history stays aligned.
