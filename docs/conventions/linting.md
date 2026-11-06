# Linting

Lint turns the mechanical parts of our conventions into checks that fail
`./gradlew check`. Judgement rules (simple linear code, no speculative
defences, meaningful names) stay as agent rules.

## Tools

| Project type | Formatter | Linters | Config |
|---|---|---|---|
| Java (nbn-recorder-workers, nbn-core) | Spotless with palantir-java-format | PMD, SpotBugs (main code only) | `config/pmd/ruleset.xml`, `config/spotbugs/exclude.xml` |
| Grails (nbn-recorder-grails, nbn-components-plugin) | Spotless: import order and whitespace only | CodeNarc | `config/codenarc/codenarc.groovy` |

Repos of the same type keep **identical** ruleset files. Change them together.

Reports are written to `build/reports/pmd/`, `build/reports/spotbugs/` and
`build/reports/codenarc/`.

## Where lint runs

- **Locally and by agents:** `./gradlew spotlessApply`, then `./gradlew check`.
  This is the only enforcement point (rule `lint-verification`).
- **Not in CI:** Travis and CodeBuild do not run the linters, so a lint failure
  never breaks a build or blocks publishing.

## Fix or suppress

Fix the code by default. Suppress only when the flagged code is deliberate, at
the narrowest scope, with a reason:

| Scope | Java (PMD) | Groovy (CodeNarc) |
|---|---|---|
| Line | `// NOPMD - RuleName: reason` | `// codenarc-disable-line RuleName` |
| Method | `@SuppressWarnings("PMD.RuleName")` | `@SuppressWarnings('RuleName')` |

Put a one-line comment above a method-level suppression saying why. Prefer the
method over the class, so new code added to the class is still checked. For
example, job runners and pollers suppress `AvoidCatchingGenericException`
on each boundary method rather than on the class.

If a rule is wrong across the whole codebase, change the ruleset in every repo
of that type instead of suppressing it repeatedly. Do this only with agreement.

## Agent rules now enforced by lint

| Rule | Enforced by | Still judgement |
|---|---|---|
| `readable-formatting` | Spotless (layout); `IfStatementBraces`, `ForStatementBraces` etc. (CodeNarc), `ControlStatementBraces` (PMD) | whitespace between logical steps, naming, wrapping style |
| `lean-controllers` | `MethodSize`, `AbcMetric`, `CyclomaticComplexity` (CodeNarc) | what belongs in a command object or service |
| `service-layer` (catch only at boundaries) | `CatchException`, `CatchRuntimeException` (CodeNarc), `AvoidCatchingGenericException` (PMD) | whether a catch is a real recovery path |
| `testing`, `tdd-design-review-loop` (no leftover debugging) | `Println` (CodeNarc), `SystemPrintln` (PMD) | |
| `command-request-adapters` | `GrailsMassAssignment`; `ServiceHttpDependency` rejects explicit HTTP request/response types in services | validation, DTO shape, and whether a Map is request-shaped |
| domain declarations | `GrailsDuplicateConstraint`, `GrailsDuplicateMapping`, `GrailsDomainWithServiceReference` | domain modelling |
| `multitenancy` | `TenantBoundary` flags known bypass calls and annotations in web controllers/services; `WebLayerJdbc` flags direct JDBC dependencies there | query correctness, authentication, relationships, filesystem isolation, indirect/dynamic access |
| `edit-form-versions` | `EditFormCommand` (custom, where adopted) fails a `Save*Command` in controllers that doesn't extend `EditFormCommand`, or another command declaring its own `version` | whether the service's `update` calls `assertUnchanged` |
| `simple-linear-code` | `CognitiveComplexity` (PMD), `NestedBlockDepth` (CodeNarc) as a backstop | when to extract a method |

`NPathComplexity` is deliberately not used: it penalises flat lists of guard
clauses, which is the style `simple-linear-code` asks for.

## Tenant boundary review guard

The Grails repositories load `config/codenarc/TenantBoundaryRule.groovy` as a
CodeNarc AST rule. It applies only under `grails-app/controllers/` and
`grails-app/services/`, including nested directories. It flags:

- Known tenant switching/bypass methods (`withId`, `withoutId`, `withTenant`,
  `withoutTenant`, `withCurrent`) and `@Tenant` / `@WithoutTenant` annotations.
- Native queries, direct HQL calls, JDBC connection access, Hibernate JDBC
  work callbacks, and disabling Hibernate filters.

Method checks use the method name rather than receiver type so ordinary
Groovy dynamic calls are still checked. An unrelated method with the same
name may need a documented exception. Annotation imports, including aliases and wildcard imports,
are resolved from the AST. Comments and string literals are not treated as
calls. Static imports of the listed methods, including aliases, are checked too.

Prefer the normal tenant-scoped GORM API. For a necessary raw query, review
all reads/writes and parameter bindings, then add a line or method-level
`TenantBoundary` suppression with the tenant-scoping reason. Shared global
administration data may also need a deliberate exception. A suppression is
a review decision, not evidence that SQL is tenant-safe; changes to suppressed
code need renewed review.

`WebLayerJdbc` independently flags direct references to `groovy.sql`,
`java.sql`, `javax.sql`, and Spring JDBC in these web directories.
`ServiceHttpDependency` rejects explicit `GrailsParameterMap`, servlet request,
and servlet response references in services.

CLI commands and tests may legitimately switch tenants and are outside these
web guards. Workers have a separate JDBC/job contract and are not covered.
These guards do not prove isolation, inspect arbitrary SQL, check all helpers
under `src/main/`, or detect every reflective/dynamically constructed call.
They do not replace real-database cross-tenant integration tests.

`lintRuleTest` runs with `check` in both Grails repositories. Its source fixtures
exercise the loaded configuration, unsafe calls/annotations, permitted normal
GORM/CLI/test code, and narrow suppression behaviour. Changes to custom rule
sources are also tracked as CodeNarc task inputs so cached checks are invalidated.
