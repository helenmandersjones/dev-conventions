# Service layer (enterprise Java style)

Conventions for **Grails services** in this codebase. Layers above the service (controllers, exception handlers, interceptors) decide how exceptions become HTTP status, flash messages, or JSON — **services do not** handle HTTP.

## Rules

- **Do not return `null` for failures in command methods** (mutations, enqueue, persist, side effects). Use exceptions.
- **Transactional scope for GORM methods:**
  - Prefer **method-level** `@Transactional` annotations so transaction boundaries are explicit.
  - Use **`@Transactional(readOnly = true)`** for read-only lookup/list/preview methods that only query GORM entities.
  - Use **`@Transactional`** for write methods (create/update/delete/enqueue/intentional flush).
  - Avoid class-level `@Transactional` on mixed services (reads + writes, batch work, or external/JDBC processing).
  - Keep transactions **small** and focused on the minimum GORM work needed.
- **Throw exceptions** for invalid input and illegal state:
  - **`IllegalArgumentException`** — bad parameters (missing required values, malformed ids, invalid format).
  - **`IllegalStateException`** — preconditions not met (expected files missing on disk, wizard state inconsistent with operation).
  - **`grails.validation.ValidationException`** — domain object failed validation (`errors` populated); include the `Errors` object when throwing.
- **Exceptions are exceptional, not form UX:** User-correctable request/form
  problems should normally be represented as command-object validation errors
  before a write service is called. A service can still throw for bad input,
  stale state, race conditions, or domain validation failures that should not
  be reachable through a valid command. Controllers should not routinely catch
  these exceptions per action to re-create form errors; let them bubble to
  central error handling unless there is a deliberate local recovery path.
- **Finder / read methods may return `null`** when the resource is genuinely absent (e.g. optional lookup by id, no saved file yet). Prefer documenting “null means not found”.
- **Do not catch exceptions only to log, rethrow, or wrap** (e.g. in `IllegalStateException`) when there is nothing to fix locally — **let library and framework exceptions propagate** with their original type and message.
- **Orchestration boundary:** For a long-running command with a single terminal failure path (e.g. fail job + user message), use a **domain failure type** only for **known** outcomes (e.g. limit exceeded, missing file). Let **unexpected** failures propagate as ordinary exceptions and handle them **once** at the orchestration entry (e.g. `catch (DomainFailure e) { … } catch (Exception e) { log; fail(…) }`), rethrowing types that must not be converted to a failed job (e.g. `IllegalArgumentException`). **Do not** wrap every inner method in `try/catch` only to re-wrap unknown errors if the top level already maps `Exception` to the same outcome.
- **Catch only when you must run cleanup** (e.g. delete a partially persisted entity, then rethrow the same cause) — **rollback / compensating action**, then `throw e` or rethrow with cause.
- **Do not log in service methods** unless the log line adds **real diagnostic context** not already in the stack trace.
- **Keep happy-path code linear** — validate early, then proceed without nested failure branches.

## Multitenancy

For Multitenant GORM entities in a web request, do not pass `User` or
`tenantId` solely to enforce isolation — rely on the session tenant. See
[`multitenancy.md`](multitenancy.md).

## Rationale

Clear failure modes, testable contracts, and a single place (typically
`@ControllerAdvice`, Grails exception handling, or an error controller) to map
exceptions to user-facing responses. Full-page requests should receive the
standard error page. HTMX requests can receive a central toast/fragment error
response with an error status. Form actions should only handle the expected
form-validation path locally.

## Transaction examples

```groovy
import grails.gorm.transactions.Transactional

class PresetService {

    @Transactional(readOnly = true)
    List<Preset> listPresets(User user) {
        Preset.findAllByUser(user)
    }

    @Transactional
    Preset savePreset(User user, String payload) {
        Preset preset = new Preset(user: user, payload: payload)
        preset.save(failOnError: true, flush: true)
        preset
    }
}
```
