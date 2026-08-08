---
name: resume-task-handoff
description: >-
  Resume multi-slice TDD task work. Read docs/tasks/CURRENT_HANDOFF.md, then the
  linked *-handoff.md and task file. Use when the user says "resume task handoff",
  "continue from handoff", "@CURRENT_HANDOFF", or starts work on docs/tasks after a break.
---

# Resume task handoff

## When to use

The user is continuing **in-progress work** tracked under **`docs/tasks/`** with slice handoffs, often after a **new chat** with no thread history.

## Steps

1. Read **`docs/tasks/CURRENT_HANDOFF.md`**. If it has no links or says no active task, say so and ask which `open/*.md` task to use (or read **`docs/tasks/completed.md`** / **`open/`** as needed).
2. Open the linked **`open/<slug>-handoff.md`** — use the **latest slice** section and **Next slice** for what to do next.
3. Open the linked **task** file for acceptance criteria and slice tracker.
4. Proceed with implementation; after each GREEN slice, update the **handoff** file per **`docs/tasks/HANDOFF-TEMPLATE.md`** (see **`docs/tasks/README.md`**).

## Do not

- Treat this as required for every coding session — only when the user is on an **active task list** with handoffs.
- Require editing **`CURRENT_HANDOFF.md`** on every slice; the human updates it when **switching** tasks or when **finishing** a task.
