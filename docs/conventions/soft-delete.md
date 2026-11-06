# Soft delete

Use this convention when a project/domain has chosen recoverable soft delete: deleting a row means setting a nullable timestamp such as `deleted`, not removing the database row.

## Default approach

- Add a nullable timestamp field, normally `Date deleted`, usually through a small shared trait (`SoftDeletable`).
- Normal application reads should exclude deleted rows silently in the service layer, for example `Domain.where { deleted == null }`.
- Keep list/count/get/select methods active-only by default. Callers should not need to remember to filter out deleted records.
- If deleted records are needed for maintenance, audit, restore, or investigation, make that an explicit query path.
- Delete **one** record through GORM: load it, set `deleted`, save. Delete **many** records with one HQL update.

## Deleting one record

Load the active record through the service's normal tenant-scoped `get`, run any checks, then call the trait's `softDelete`:

```groovy
@Transactional
boolean softDelete(Long id) {
    Domain domain = get(id)               // active-only and tenant-scoped
    if (!domain) {
        return false
    }
    domain.softDelete(flush: true, failOnError: true)
    true
}
```

Why a GORM save rather than an update query:

- **Stale edits are caught.** The save goes through Hibernate's version check, so an edit made from an out-of-date copy fails with `OptimisticLockingFailureException` instead of silently undoing the delete. A hand-written update has to manage `version` itself.
- **Tenancy comes from GORM.** `get` already applies the tenant filter, so no explicit `tenantId` binding or `TenantBoundary` suppression is needed.
- **Domain hooks run.** `softDelete` calls the domain's `beforeSoftDelete()` cleanup.

### When the delete depends on other rows: lock

If whether a record may be deleted depends on rows another request could add at the same time (for example "refuse to delete an event that has child events or records"), take a row lock before checking, and make the code that attaches to the record take the same lock:

```groovy
@Transactional
boolean softDelete(Long id) {
    Event event = lockActiveEvent(id)
    if (!event || hasOccurrencesOrChildEvents(id)) {
        return false
    }
    event.softDelete(flush: true, failOnError: true)
    true
}

// Deleting and attaching a child must hold the same row lock until their transaction commits.
private static Event lockActiveEvent(Long id) {
    id ? Event.where { deleted == null }.findById(id, [lock: true]) : null
}
```

The check must run *after* the lock is taken. Whichever request locks first wins: a delete that commits first makes the waiting attach find no active parent; an attach that commits first makes the waiting delete see the new child. Optimistic versioning alone does not cover this, because adding a child does not change the parent row.

Prove the lock with an integration test that runs both orders in two threads against Postgres.

## Deleting many records

Use one HQL update. Bind the tenant explicitly, skip rows already deleted, and bump `version` so open copies of those rows cannot save over the delete:

```groovy
// The bulk HQL update explicitly binds the current tenant.
@SuppressWarnings('TenantBoundary')
@Transactional
int softDelete(Collection<Long> ids) {
    if (!ids) {
        return 0
    }
    Domain.executeUpdate('''
            update Domain d set d.deleted = :deleted, d.version = d.version + 1
            where d.tenantId = :tenantId and d.id in (:ids) and d.deleted is null
            ''', [deleted: new Date(), tenantId: Tenants.currentId() as String, ids: ids]) as int
}
```

Bulk updates bypass `beforeSoftDelete()`, so required relationship cleanup must be done in the service, also with tenant-bound HQL. Cleanup updates bump `version` too.

An update query does not flush the session first. If the same request has already changed one of the rows in memory, save that object before the update; otherwise the update bumps its version and the later save fails as stale.

## Domain `delete()`

Do not use `delete()` on a soft-deletable domain. The trait's `beforeDelete()` throws, so a mistaken call fails loudly and removes nothing:

```groovy
boolean beforeDelete() {
    throw new UnsupportedOperationException(
            "${this.class.simpleName} is soft-deletable: call softDelete(), not delete()")
}
```

Do not try to turn `delete()` into a soft delete inside `beforeDelete()`. GORM runs that hook during the flush, after Hibernate has already removed the object from the session, so the hook can only fall back to an update query, without a version check or tenant scope. It also runs only when the session flushes, not when `delete()` is called.

Add an integration test proving `domain.delete(flush: true)` throws and leaves the row unchanged.

## Writing the trait

Keep the trait small: the `deleted` field, `softDelete(Map)`, `restore()`, the throwing `beforeDelete()`, and an empty `beforeSoftDelete()` hook.

Inside the trait, change `deleted` through its setter, `setDeleted(...)`, never `deleted = …`. In a trait, plain assignment writes the field directly and skips the domain's generated setter, which is where GORM records the change; the save then writes nothing, without an error. Setting `domain.deleted` from service code goes through the setter and is fine.

## Relationships

- Avoid cascade delete for soft-deleted entities. Cascades can make ordinary relationship edits remove rows unexpectedly.
- Use explicit cleanup for references that must not point at deleted rows, such as clearing a primary contact or removing an organisation from people. Put it in `beforeSoftDelete()` for single deletes, and in the service for bulk deletes.
- Decide deliberately whether cleanup should include already-deleted related records. If the foreign key should be cleared regardless of related row state, filter by the relationship id rather than only active rows.

## What not to add by default

Do not add these unless the user/project explicitly chooses them:

- PostgreSQL triggers to rewrite `DELETE` into `UPDATE`.
- Parallel `*_deleted` archive tables for every soft-deleted table.
- Native SQL helper layers just to avoid HQL.
- Generic repository frameworks or broad abstractions around all domains.
- Speculative support for future restore/audit workflows that do not exist yet.

These approaches can be valid in a specific system, but they raise operational and testing cost. The default is a clear service-level soft delete with active-only reads.

## Testing

Cover both normal reads and mutation paths:

- list/count/get/select methods exclude deleted records
- update paths cannot attach active records to deleted association targets
- service soft-delete methods set `deleted` and clean required references
- bulk and single soft-delete paths behave consistently
- a stale copy cannot save over a soft delete
- direct domain `delete()` throws and leaves the row in place

Check that a soft delete actually writes with an integration test that reads the row back from Postgres. Unit tests on the in-memory datastore do not do Hibernate's change tracking, so a save that writes nothing still passes there. Use unit tests for service contracts, tenant scoping, and simple query shape checks.
