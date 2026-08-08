# Multi-tenancy (GORM discriminator)

How tenant scoping works for **MultiTenant** domain entities in this stack. Applies to Grails web apps using `DISCRIMINATOR` mode and `SessionTenantResolver`, plus CLI and separate workers where noted.

## Default (web request)

1. Controllers require authentication (`@Secured` / intercept-url map).
2. An interceptor (e.g. `TenantResolverInterceptor`) sets the session tenant from the logged-in user (`User.tenantId`), or denies users with no tenant (`403`).
3. Domain classes implement `MultiTenant`. GORM filters reads/writes by the **session tenant**.

Therefore:

- **Do not** pass `User` or `tenantId` into service methods solely to enforce tenant isolation on Multitenant GORM entities.
- Service APIs look like `accept(jobId)`, `get(id)`, `softDelete(id)` — missing / other-tenant resources appear as **not found** (`null` or `IllegalArgumentException`), not as an explicit cross-tenant forbid.
- Pass `User` only when the user is a **domain argument** (audit `createdBy`, ownership that is not tenancy, preferences), not as a tenancy key.
- Controllers may resolve `currentUser` for authn/audit; they should not re-check `job.tenantId == user.tenantId` when Multitenant filtering already applies.

Reference shape: contact services (`PersonService`, `OrganisationService`); occurrence import `accept` / `reject`.

## Outside a web request

| Runtime | Tenant binding |
|---|---|
| **CLI / Grails commands** | Wrap Multitenant work in `Tenants.withId(...)` (or equivalent). |
| **Separate worker process** (no HTTP session) | Pass / use explicit `tenantId` from the job row or claim (filesystem paths, JDBC). Do not assume a session tenant. |
| **Tests** | Establish tenant context with `Tenants.withId(...)` when exercising Multitenant domains (see [`testing.md`](testing.md)). |

## Explicit `tenantId` parameters that remain valid

Disk paths and non-GORM APIs are **not** filtered by Multitenant. Methods such as `TenantDataDirectoryService.stagingCsvFile(tenantId, …)` or CSV preview against a path **must** take `tenantId` (or an equivalent path root). That is filesystem scoping, not a substitute for GORM tenancy.

## Related

- Project tech design (outcomes, feature notes): `docs/technical-design/` in the app repo (not this shared conventions tree).
- Service exceptions / transactions: [`service-layer.md`](service-layer.md).
