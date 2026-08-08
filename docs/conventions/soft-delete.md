# Soft delete

Use this convention when a project/domain has chosen recoverable soft delete: deleting a row means setting a nullable timestamp such as `deleted`, not removing the database row.

## Default approach

- Add a nullable timestamp field, normally `Date deleted`.
- Normal application reads should exclude deleted rows silently in the service layer, for example `Domain.where { deleted == null }`.
- Keep list/count/get/select methods active-only by default. Callers should not need to remember to filter out deleted records.
- If deleted records are needed for maintenance, audit, restore, or investigation, make that an explicit query path.
- Prefer GORM/HQL for service delete operations, for example `Domain.executeUpdate(...)`, unless the project has deliberately chosen native SQL for that area.

## Delete methods

Service delete methods should be explicit and easy to review:

```groovy
@Transactional
boolean softDelete(Long id) {
    if (!id) {
        return false
    }
    String tenantId = Tenants.currentId() as String
    OtherDomain.executeUpdate(
            'update OtherDomain o set o.someReference = null where o.tenantId = :tenantId and o.someReference.id = :id',
            [tenantId: tenantId, id: id]
    )
    int updated = Domain.executeUpdate(
            'update Domain d set d.deleted = :deleted where d.tenantId = :tenantId and d.id = :id and d.deleted is null',
            [deleted: new Date(), tenantId: tenantId, id: id]
    ) as int
    updated > 0
}
```

Keep required relationship cleanup inline when it is central to the delete contract and short enough to read. Extract only for meaningful duplication or genuinely complex logic.

Bulk soft-delete methods should use the same pattern with `id in (:ids)`, return the affected row count, and handle empty input directly.

## Domain `delete()`

If accidental hard deletes are a realistic risk, intercept domain `delete()` so it also performs a soft delete. Add integration coverage proving that direct `domain.delete(...)` leaves the row present and sets `deleted`.

When using a trait or shared helper for this, keep it small. The shared behaviour should only set/clear the timestamp and offer optional hooks for domain-specific cleanup.

## Relationships

- Avoid cascade delete for soft-deleted entities. Cascades can make ordinary relationship edits remove rows unexpectedly.
- Use explicit cleanup for references that must not point at deleted rows, such as clearing a primary contact or removing an organisation from people.
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
- direct domain `delete()` is soft if the domain exposes that guarantee

Prefer integration tests for GORM/HQL behaviour and unit tests for service contracts, tenant scoping, and simple query shape checks.
