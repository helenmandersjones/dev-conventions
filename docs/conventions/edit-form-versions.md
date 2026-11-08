# Edit form versions (optimistic locking)

Use this convention for every form that edits an existing record. Rule: `cursor/rules/edit-form-versions.mdc`.

## The problem

Two people open the same edit form. The first saves. The second saves a few minutes later, and their form
still holds the record as it was when they opened it, so it silently replaces the first person's changes.
Neither is told.

GORM versions every domain class, and Hibernate refuses a save whose version is out of date. But the
service loads the record fresh just before saving, so the version it checks is always current. Hibernate's
check only catches two saves colliding in the same instant, never a form opened earlier. The form has to
carry the version it was opened at.

## The pattern

| Layer | Piece | What it does |
|---|---|---|
| Command | `EditFormCommand` base class | Carries `id` and `version`, gives `isEditing()`, and validates `version` against the record's current version. A stale form gets a field error on `version`. |
| Form | a tag, e.g. `<nbn:editedRecord command="${cmd}"/>` | When editing: hidden `id` and `version`, and the message if the save was refused. Nothing when creating. |
| Service | `EditFormVersion.assertUnchanged(record, version)` | Throws Spring's `OptimisticLockingFailureException` if the record has moved on. Covers other callers and a save that lands between validating and saving. |
| Errors | the central error controller | Answers `OptimisticLockingFailureException` with 409 and the same message. |
| Message | one i18n key, e.g. `edit.changedByOther.message` | "Someone else changed this since you opened it. Reload the page to see their changes, then make yours again." |

What the user sees:

- **Normally:** the form comes back with their input and the message. The check runs during validation, before
  the action does anything.
- **In the rare race,** a save landing between validation and the save: a 409 page or HTMX toast with the same
  message. The user loses their input, which is acceptable for a window of milliseconds.
- **In every case,** the other person's change survives.

The re-shown form keeps the old version on purpose: pressing Save again is refused until the user reloads.

## Building it in a project

Keep it to these few pieces; don't spread the check through each command and service.

```groovy
abstract class EditFormCommand implements Validateable {
    Long id
    Long version

    boolean isEditing() { id != null }

    abstract Class editedDomainClass()

    static constraints = {
        id nullable: true
        version nullable: true, validator: { Long value, EditFormCommand cmd ->
            EditFormVersion.check(cmd.editedDomainClass(), cmd.id, value)
        }
    }
}

class EditFormVersion {
    static final String CHANGED_BY_OTHER = 'edit.changedByOther.message'

    static Object check(Class domainClass, Long id, Long openedAt) {
        if (id == null) {
            return true
        }
        openedAt != null && openedAt == domainClass.get(id)?.version ?: CHANGED_BY_OTHER
    }

    static void assertUnchanged(Object record, Long openedAt) {
        if (record.version != openedAt) {
            throw new OptimisticLockingFailureException(
                    "${record.getClass().simpleName} ${record.id} changed since version ${openedAt} was opened")
        }
    }
}
```

Subclasses add their own `static constraints`; Grails merges them with the base class's.

`domainClass.get(id)` is tenant-filtered for `MultiTenant` domains, so another tenant's id looks like a stale
version, never like someone else's record.

## Adding an edit form

1. The command extends `EditFormCommand`, is named `Save*Command`, and implements `editedDomainClass()`. Its
   `from<Domain>` factory copies `version` along with `id`.
2. The form renders the identity tag where the message should show, usually after the non-field errors.
3. The service's `update` takes the version and calls `assertUnchanged` before changing anything.
4. The controller passes `cmd.version` and doesn't catch the exception.
5. An integration spec saves with a stale version and checks the first change survives.

## Enforcing it

A CodeNarc rule can keep new edit forms on the pattern: fail the build when a `Save*Command` in
`grails-app/controllers` doesn't extend `EditFormCommand`, or when another command declares its own `version`.
Key on the `Save*Command` name rather than on having an `id`: list and search commands often have an `id` too.
The rule can't see a service `update` that forgets `assertUnchanged`; the command's check still covers almost
every real case. See `docs/conventions/linting.md` for custom rules.

## Where it doesn't apply

- Forms that only create.
- Single-purpose actions such as delete or remove-item, which act on the record as it is now.
- Bulk updates by HQL, which must set `version = version + 1` themselves.
