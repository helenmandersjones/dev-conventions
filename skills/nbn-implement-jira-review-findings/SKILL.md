---
name: nbn-implement-jira-review-findings
description: >-
  Implement an explicit set of Jira issues produced by a branch review on the
  current feature branch, normally in the current task with per-issue review,
  tests, and commits. Use when the user asks to fix, address, or work through
  Jira review findings; not for creating tickets or implementing an unrelated
  issue.
---

# Implement Jira review findings

Resolve reviewed Jira findings on the user's current feature branch with a
proportionate implementation and acceptance workflow. The user retains control
of pushing and merging.

Invoke the skill with the Jira keys to implement, for example:

```text
$nbn-implement-jira-review-findings AI-3, AI-4, AI-5
```

Treat only the supplied keys as authorized work. Accept commas, spaces, or an
inclusive range such as `AI-3 through AI-5`; normalize them to an ordered,
deduplicated list before starting. If no keys are supplied, ask for them rather
than selecting issues from the Jira backlog.

Invocation with explicit keys also authorizes the two routine workflow
transitions described below for those keys only. It does not authorize Jira
comments, edits, assignments, worklogs, links, or any other mutation.

## Establish the work set

- Confirm the repository, current feature branch, base branch, and Jira issue
  keys. Do not switch branches merely because a ticket records an older branch.
- Read each issue from Jira, including acceptance criteria and the reviewed
  commit SHA. Load the repository's `AGENTS.md`, applicable rules, task history,
  and conventions before planning changes.
- Inspect the current code and revalidate every finding. A Jira issue is review
  evidence, not proof that its diagnosis or proposed remediation is still
  correct. Do not implement a stale, duplicate, already-fixed, or invalid
  finding. Explain the evidence and ask before changing that Jira issue.
- Order valid issues by risk and dependency. Prefer correctness and security
  prerequisites before performance or user-interface work, but adjust when one
  issue enables or substantially changes another.
- Report the proposed order and any overlap. Use one implementation stream when
  issues touch the same code or schema.

## Choose a proportionate execution mode

Implement straightforward findings directly in the current task. This is the
default: it avoids delegation overhead while preserving per-issue validation,
tests, diff review, and commits.

Use a separate implementation agent only when:

- the user requests delegated or independent implementation;
- the change is unusually broad, security-critical, migration-heavy, or has
  enough interacting behavior that independent implementation materially
  improves confidence; or
- a bounded research or verification subtask can run independently and will
  save meaningful time.

Briefly state when delegation is being used and why. Do not delegate routine,
localized findings merely because delegation is available. The primary agent
must not make concurrent edits to the same worktree as an implementation agent.

When delegating implementation, give the agent one bounded Jira issue with:

- the issue key and current Jira description;
- repository, current branch, and base branch;
- applicable repository/task instructions;
- the requirement to re-check assumptions and report conflicts;
- the repository's required test/design workflow;
- authority to edit only what that issue reasonably requires;
- no authority to push, merge, or mutate Jira.

Reuse the same implementation agent for review corrections when practical. Do
not run overlapping issue implementations concurrently in a shared worktree.

## Per-issue acceptance loop

For each valid issue:

1. Establish the pre-change state and isolate unrelated user changes.
2. Immediately before implementation, move the issue to `In Progress` when
   that transition is available. Do not move an issue backwards from a later
   status.
3. Follow the repository's test-first, task-file, migration, and design-review
   conventions. Do not weaken production behavior to make a test pass.
4. Inspect the actual diff and relevant surrounding code after implementation.
   When an agent was used, do not accept its summary as evidence.
5. Check the Jira acceptance criteria, regression risk, authorization,
   concurrency and transaction boundaries, schema compatibility, performance,
   and consistency with comparable project code to the degree relevant.
6. Run proportionate focused tests. If review finds a defect, correct it in the
   current task, or give the delegated agent concrete evidence, then repeat
   review and verification until accepted or genuinely blocked.
7. Ensure task/handoff records required by the repository are current.
8. Commit the accepted issue separately when repository conventions require
   commits or the user requested them. Include the Jira key in the commit
   subject. Do not include unrelated work.
9. After the implementation, review, tests, and commit have all passed, move
   the issue to `Review` when that transition is available.

Jira status transitions are best-effort and must not make code work fragile or
slow. Discover the issue's available transitions, use an exact matching status
when present, and make at most one transition attempt per intended status. If a
transition is unavailable or fails, continue the code workflow and report it.

Do not begin a dependent issue until its prerequisite is accepted. It is fine
to continue to the next independent issue after acceptance without asking for
another confirmation when the user authorized the whole displayed work set.

## Jira and repository boundaries

- Invocation authorizes only the selected issues' `In Progress` and `Review`
  transitions. Comments, edits, assignments, worklogs, links, other
  transitions, or mutations to other issues still require explicit permission.
- Code-fix authorization does not authorize pushing, opening or merging a pull
  request, deleting branches, or rewriting history.
- Work on the current feature branch unless the user asks for another branch or
  worktree. Preserve unrelated changes already present there.
- If a ticket requires a materially larger product decision than its acceptance
  criteria establish, stop that issue and request direction rather than
  silently expanding scope.

## Final branch gate

After all accepted issues are implemented:

- run the full relevant test suite and any migration verification required by
  the repository;
- review the complete feature-branch diff against the base branch, including
  interactions between fixes;
- confirm every issue as fixed, invalid, already fixed, or blocked, with
  evidence;
- report commits, tests, remaining risks, and the outcome of Jira transitions;
- leave the branch unpushed and unmerged for the user unless they explicitly
  request otherwise.

Completion means implementation, diff review, and verification all pass. When
an implementation agent was used, its green test run alone is not sufficient.
