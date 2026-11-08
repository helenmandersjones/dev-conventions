---
name: nbn-review-branch-to-jira
description: >-
  Review a code branch against a base branch and turn confirmed, actionable
  findings into deduplicated Jira issues. Use when the user asks to review a
  branch and create, raise, draft, or update Jira tickets from the findings;
  not for an ordinary review with no ticket workflow.
---

# Review branch to Jira

Produce an evidence-backed branch review and a traceable set of Jira issues.
Keep review conclusions separate from permission to mutate Jira.

## Establish scope

- Confirm the repository, review branch, and base branch from the request and
  workspace. Use the user's base branch when supplied; otherwise use the
  repository's established integration branch and state the choice.
- Record the reviewed branch name and exact commit SHA before analysis. If the
  branch changes before issue creation, disclose that and ask whether to review
  the new commits or ticket the recorded snapshot.
- Load the repository's applicable `AGENTS.md`, review rules, and conventions.
  Inspect comparable code where those instructions require it.
- Preserve the requested review emphasis. For a broad engineering review,
  examine correctness, authorization, injection and data exposure, concurrency,
  transactions, database/schema behavior, resource use, and performance.

## Review

Review the base-to-branch diff and the surrounding code required to validate
each suspected issue. Run proportionate read-only checks and tests. Do not
create a ticket for:

- style preferences without a concrete maintenance or correctness cost;
- speculative future behavior;
- an issue already present on the base branch unless the branch makes it
  newly reachable, materially worse, or directly relevant to its feature;
- a claim that cannot be tied to a specific failure scenario and code location.

Rank confirmed findings by impact and likelihood. Give each finding a concise
title, affected locations, failure scenario, and remediation outcome. Report
when no actionable findings remain.

## Prepare Jira issues

Before drafting, discover the Jira site and project rather than guessing IDs,
issue types, fields, or workflow configuration. Use the project key supplied by
the user or ask for it if it cannot be discovered safely.

For every confirmed finding:

1. Search the target project for a likely existing issue using distinctive
   terms from the finding. Do not create a duplicate. Present a likely match to
   the user and recommend commenting or updating only when appropriate.
2. Choose the project's defect issue type, normally `Bug`, unless the user
   specifies another type.
3. Draft a summary and description containing:
   - repository, reviewed branch, base branch, and commit SHA;
   - review severity and category;
   - concrete problem and impact;
   - affected files or components;
   - acceptance criteria describing the corrected behavior;
   - focused tests or verification.
4. Group issues with stable labels rather than an Epic unless the user asks for
   an Epic or supplies an existing parent. Prefer `code-review`,
   `feature-branch-review`, and one normalized feature label, plus useful
   category labels such as `security`, `performance`, `database`, or
   `data-integrity`. Confirm the project supports labels.

Keep one independently actionable finding per issue. Combine findings only when
they have the same root cause and cannot reasonably be fixed or verified apart.

## Approval and creation

Creating, editing, linking, or commenting on Jira issues is an external
mutation. A request to review a branch does not authorize it.

- Show the final proposed issue count, issue type, summaries, grouping fields,
  and any duplicate dispositions before creation.
- Obtain explicit approval to create the displayed set. If the user already
  explicitly authorized creation of a sufficiently specific set, do not ask a
  redundant second time.
- Treat approval as applying only to that displayed set. Stop and ask again if
  creation would require materially different tickets, a new parent, broader
  labels, assignments, transitions, or changes to existing issues.
- Create issues independently so one failure does not conceal which mutations
  succeeded. Never blindly retry a timed-out creation: search for the proposed
  summary and reviewed SHA first to avoid duplicates.
- Do not assign people, set sprint/fix-version, transition status, or create an
  Epic unless the user requested it.

After creation, read the created issues back from Jira. Verify their keys,
summaries, issue types, statuses, descriptions, and grouping labels. Report
clickable issue links and any partial failure or rejected field accurately.

If Jira write access is unavailable, finish the review and provide
copy-ready drafts; do not substitute another tracker without permission.
