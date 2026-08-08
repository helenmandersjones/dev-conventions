# Testing conventions

Guidance for **unit** and **integration** tests so they mirror real behaviour instead of weakening production code.

## Prefer realistic setup over special-case implementation

- **Set domain and environment state in the test** (or in shared test helpers) so it matches what the application would have **after** the normal upstream steps: correct `status` on jobs, files where the code expects them, tenant context, etc.
- **Do not change production code** to accept a looser state “so the test can call it directly.” If a service method’s contract is “only invoke me when X is already true,” the test should persist X (or call the component that establishes X), not add a test-only branch in the implementation.

## Multi-step flows

When the production path is **A → B → C** (e.g. enqueue → worker claims → runner executes), a test that targets **C** alone should still **establish the world as if B happened**, unless the test is explicitly unit-testing B in isolation with mocks.

Example (occurrence import): the Java `ImportJobRunner#run` is defined to run a job that is **already claimed** (`RUNNING` with `startedAt` set). Tests that call `run` without going through `OccurrenceImportJobProcessorService` should **save the job in that state** (or run the processor first), not expect the runner to promote `QUEUED` → `RUNNING` for convenience.

## Transaction boundaries in integration tests

If assertions run in a **new** transaction while the work under test stayed in an **uncommitted** outer transaction, you can see stale or empty state. Use **`withNewTransaction { … }`** (or an equivalent) around the action when the test must read **committed** results, matching how scheduler threads behave in production (no enclosing test transaction).

## Related docs

- Service behaviour and exceptions: [`service-layer.md`](service-layer.md)
- Multitenancy (`Tenants.withId`, session tenant): [`multitenancy.md`](multitenancy.md)
- Replace features vs parallel legacy (pre-release defaults): [`evolution-and-compatibility.md`](evolution-and-compatibility.md)

## TDD + design workflow (required)

Use this loop for every task and slice:

1. **RED**: write failing tests only.
2. **GREEN**: make tests pass with the smallest reasonable change.
3. **DESIGN REVIEW** (no code changes): review implementation against project patterns and list design issues:
   - misplaced responsibility (controller vs service, etc.)
   - unnecessary abstractions / over-engineering
   - deviations from existing style and conventions
   - overly defensive code (for example excessive try/catch)
4. **REFACTOR**: improve structure without changing behaviour.
   - align with existing patterns
   - simplify code
   - remove unnecessary abstractions
5. **VERIFY**: rerun tests.

Task/slice completion requires all of the following:
- tests pass
- design is simple
- implementation follows existing patterns
- unnecessary abstractions are removed
