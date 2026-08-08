---
name: black-box-tests-from-public-api
description: >-
  Write black-box tests from a type's public API only (signatures, public
  constants, declared exceptions, brief Javadoc). Use when the user asks for
  black-box tests, tests from the public API, or a thin test contract for an
  interface/class/util — not when they want implementation-driven or white-box
  tests.
---

# Black-box tests from public API

Work like a human tester: invent inputs from the **public surface**, reason about
expected results from the **intended** meaning of the API, and assert those.

## Sources allowed

Prefer a **generated API surface** when the project has one (e.g.
`api-surface/generated/**` from `./gradlew extractApiSurface`) — that is the
public signatures + Javadoc without method bodies.

Otherwise, from the target type (and only these):

- Public method/function signatures (params, return type, thrown exceptions)
- Public constants / nested types used by that API
- Brief Javadoc or one-line docs on those members, if present
- Existing project test framework and conventions (where tests live, naming,
  assertion style)

Optional, only if the user points at them or signatures alone are underspecified:

- A few **intent bullets** supplied by the user (e.g. “invalid grid ref → null”)
- Related user/dev docs that state intended behaviour

## Sources forbidden

- Method / function **bodies** (and the real `.java` when the user has
  deny-read it — use the API surface Javadoc instead)
- Private helpers, fields, or algorithms
- Existing tests as something to copy (they may inform framework style only)
- Call-site implementation details that encode current quirks

If you already have the source file open, **do not read past the public
signatures and member docs**. Prefer the generated API surface when present.

## Workflow

1. Identify the target type and its **public** API.
2. List candidate cases the way a human would: typical values, boundaries,
   null/empty/blank (if relevant), invalid inputs, and any documented errors.
3. For each case, state **input → expected outcome** (return value, thrown type,
   or null). Prefer concrete examples over abstract prose.
4. Where the signature alone does not decide behaviour, either:
   - ask the user for a one-line intent, or
   - mark the case as **underspecified** and skip asserting a guessed oracle
5. Write tests that match project conventions. Do **not** produce a long
   “behavioral contract” document unless the user explicitly asks for one.

## Output shape

Default deliverable: **tests** (or a short checklist of cases, then tests).

Per method, keep notes minimal — only what a human would jot before coding:

```text
methodName(Type a, Type b) -> ReturnType
- typical: ... → ...
- boundary: ... → ...
- invalid: ... → throws X / returns null
```

No implementation notes. No private API. No algorithm description.

## Do not

- Reverse-engineer expectations from the current implementation
- Invent precise numeric/string oracles for domain-hard cases without intent
  from the user or docs (e.g. exact CRS transform digits) — ask or leave soft
- Expand into a novel-length contract by default
