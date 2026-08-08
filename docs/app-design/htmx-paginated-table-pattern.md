# htmx paginated table pattern for GSP views

This guide describes a pattern for building paginated, sortable tables with htmx in Grails/GSP views.

The goal is to make each table self-contained, predictable, and easy to reuse as a component.

## The pattern

Use a small number of clearly defined pieces:

1. A wrapper element for the table component
2. A hidden state form containing the shared table state
3. htmx controls for sorting, paging, and page size
4. A controller action that returns only the table partial
5. A command object that receives and validates the table parameters

The important rule is:

> Shared state goes in the hidden state form. Action-specific changes go on the clicked control.

For example, the state form can hold the table id, current partial, current filters, page size, and current sort. A sort link or page link should then explicitly send the values it wants to change.

## Recommended structure

```gsp
<div id="${cmd.id}" class="simple-data-table">

    <form id="${cmd.id}-state" class="d-none">
        <input type="hidden" name="id" value="${cmd.id}"/>
        <input type="hidden" name="partial" value="${cmd.partial}"/>
        <input type="hidden" name="limit" value="${cmd.limit}"/>
        <input type="hidden" name="sortBy" value="${cmd.sortBy}"/>
        <input type="hidden" name="sortDir" value="${cmd.sortDir}"/>
    </form>

    <table class="table table-sm table-striped">
        <thead>
        <tr>
            <g:each in="${header}" var="column">
                <th>
                    <a href="#"
                       hx-get="${createLink(action: 'myTablePartial')}"
                       hx-target="#${cmd.id}"
                       hx-swap="outerHTML"
                       hx-include="#${cmd.id}-state"
                       hx-vals='{"sortBy":"${column.name}", "sortDir":"${cmd.nextSortDir(column.name)}", "offset":"0"}'>
                        ${column.label}
                    </a>
                </th>
            </g:each>
        </tr>
        </thead>

        <tbody>
        <g:each in="${rows}" var="row">
            <tr>
                <g:each in="${header}" var="column">
                    <td>${row[column.name]}</td>
                </g:each>
            </tr>
        </g:each>
        </tbody>
    </table>

    <nav aria-label="Table pagination">
        <ul class="pagination pagination-sm">
            <g:each in="${1..totalPages}" var="page">
                <li class="page-item ${page == cmd.currentPage ? 'active' : ''}">
                    <a href="#"
                       class="page-link"
                       hx-get="${createLink(action: 'myTablePartial')}"
                       hx-target="#${cmd.id}"
                       hx-swap="outerHTML"
                       hx-include="#${cmd.id}-state"
                       hx-vals='{"offset":"${(page - 1) * cmd.limit}"}'>
                        ${page}
                    </a>
                </li>
            </g:each>
        </ul>
    </nav>

</div>
```

## Why use a hidden state form?

The hidden form gives every htmx request a consistent baseline set of parameters.

That means sort links, pagination links, page-size selectors, and filters do not each need to repeat every parameter manually.

For example:

```gsp
hx-include="#${cmd.id}-state"
```

This says: include the current table state whenever this control makes an htmx request.

## Why use `hx-vals` for clicked actions?

Use `hx-vals` for the specific thing the clicked control changes.

For example, a page link changes only `offset`:

```gsp
hx-vals='{"offset":"40"}'
```

A sort link changes `sortBy`, `sortDir`, and normally resets `offset`:

```gsp
hx-vals='{"sortBy":"scientificName", "sortDir":"asc", "offset":"0"}'
```

`hx-vals` is a good fit here because it makes the clicked action explicit and avoids scattering hidden inputs through every link.

## Avoid duplicate parameters where possible

Do not rely on duplicated request parameters such as two different `offset` values or two different `sortBy` values.

Although htmx can merge included inputs and `hx-vals`, duplicated parameter names can be confusing once they reach Grails, especially if server-side binding takes the first value rather than the last.

The safest rule is:

> Each parameter should have one intended value per request.

If a control changes a value, set it deliberately with `hx-vals` and make sure the server treats that as the value of truth.

## Controller pattern

The controller action should accept a command object and return the same partial.

```groovy
def myTablePartial(SimpleDataTableCommand cmd) {
    cmd.validate()

    def result = tableService.getRows(cmd)

    render template: cmd.partial, model: [
        cmd       : cmd,
        header    : result.header,
        rows      : result.rows,
        totalRows : result.totalRows,
        totalPages: result.totalPages
    ]
}
```

Keep the controller action boring. It should receive state, validate it, get data, and render the partial.

## Command object pattern

The command object should own the table request state.

Typical fields are:

```groovy
class SimpleDataTableCommand {
    String id
    String partial
    Integer limit = 25
    Integer offset = 0
    String sortBy
    String sortDir = 'asc'

    static constraints = {
        id blank: false
        partial blank: false
        limit min: 1, max: 100
        offset min: 0
        sortBy nullable: true
        sortDir inList: ['asc', 'desc']
    }

    Integer getCurrentPage() {
        (offset / limit) + 1
    }

    String nextSortDir(String columnName) {
        sortBy == columnName && sortDir == 'asc' ? 'desc' : 'asc'
    }
}
```

The command object is also the right place for small derived values such as current page, next sort direction, and offset calculations.

## URL pattern

Prefer `createLink` rather than hand-writing URLs.

Good:

```gsp
hx-get="${createLink(action: 'myTablePartial')}"
```

Avoid building URLs manually with embedded query strings unless you are very careful with encoding.

For example, this is easy to break:

```text
partial=%2FsimpleDataTableDemo%myTablePartial
```

The second slash should also be encoded if it is part of the parameter value:

```text
partial=%2FsimpleDataTableDemo%2FmyTablePartial
```

## Recognisable team pattern

Use this naming convention across the codebase:

- `${cmd.id}` for the table wrapper id
- `${cmd.id}-state` for the hidden state form
- `hx-target="#${cmd.id}"` for table replacement
- `hx-swap="outerHTML"` so the whole component refreshes consistently
- `hx-include="#${cmd.id}-state"` for shared state
- `hx-vals` for action-specific changes

This makes every paginated table behave the same way and makes it easier for developers to recognise and maintain the pattern.

## Checklist

Before committing a table component, check:

- The component has a stable wrapper id
- htmx replaces the wrapper using `outerHTML`
- shared state is held in one hidden state form
- clicked controls use `hx-vals` for the value they change
- sorting resets `offset` to `0`
- pagination preserves sorting and filters
- controller action returns only the partial
- command object validates table parameters
- URLs are generated with `createLink`

## Summary

The core idea is simple:

> Treat the table as a small stateful component. Keep the current state in one hidden form, and let each htmx control declare only the change it wants to make.

This gives us a consistent, reusable pattern for paginated and sortable tables without introducing a large JavaScript framework.
