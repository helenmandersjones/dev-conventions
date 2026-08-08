# HTMX fragment state (hx-include)

For server-rendered HTMX fragments where controls inside the fragment change
paging, sort, filters, or similar state, **do not** build query strings in the
GSP or hand-roll JSON for request params. Put state in hidden inputs at defined
**scope levels**, then wire controls with `hx-get` (partial URL only) and
`hx-include`.

## Goal

After each HTMX swap, the partial action receives enough bound command
parameters to rebuild the same fragment with updated data — without the
template hard-coding URLs or duplicating state in JavaScript.

## Scope levels

Think of fragment state in three scopes, outer to inner:

| Scope | Container | Question it answers | Changes when user clicks? |
|-------|-----------|---------------------|---------------------------|
| **1. Identity** | `#<id>-state` | Which fragment? Which partial URL? | No — stable for the life of the fragment |
| **2. Carry-through** | `[data-role="carry-through-state-params"]` | What is the fragment’s current state? | Re-rendered each swap; included on every action |
| **3. Action override** | `[data-role="<action>"]` | What does *this* control change? | Yes — only the fields this click overrides |

On each request, HTMX merges included forms. Identity and carry-through travel
with every control; the action wrapper supplies overrides (e.g. a new page or
sort column). Grails binds the merged params onto the fragment command.

## 1. Identity — `#<id>-state`

A hidden form that identifies the fragment instance and the partial action.
Include it on **every** HTMX request from this fragment.

```html
<div id="occurrence-table">
  <form id="occurrence-table-state" class="d-none">
    <input type="hidden" name="id"      value="occurrence-table"/>
    <input type="hidden" name="partial" value="/occurrence/tablePartial"/>
  </form>

  <!-- table body, pagination, … -->
</div>
```

| Field | Purpose |
|-------|---------|
| `id` | DOM id of the fragment root (`hx-target="#occurrence-table"`) |
| `partial` | URL of the partial action that re-renders this fragment |

These values do not change when the user sorts or pages. They tell the partial
*which* table and *where* to POST/get back to.

## 2. Carry-through — `[data-role="carry-through-state-params"]`

A hidden block holding **current** command state that most actions need to
preserve (sort while paging, sort while changing page size, etc.). Re-render
it on every partial response with up-to-date values. Include it on **every**
HTMX request from this fragment.

```html
<div data-role="carry-through-state-params" class="d-none">
  <input type="hidden" name="limit"   value="10"/>
  <input type="hidden" name="offset"  value="0"/>
  <input type="hidden" name="sortBy"  value="id"/>
  <input type="hidden" name="sortDir" value="desc"/>
</div>
```

Exact field names match the fragment command (e.g. `SimpleDataTableCommand` in
the plugin demo, or an adapter command in the host app). The role name describes
*behaviour* (“params that carry through”), not a specific feature like
pagination.

## 3. Action override — `[data-role="<action>"]`

A wrapper around the clickable control with hidden inputs for **only the fields
this action changes**. HTMX includes it via `closest [data-role='…']` from the
click target.

Use a **specific** action name (`sort-link`, `page-link`, `page-size-form`,
etc.) so the intent is obvious in the template.

### Example: go to page 3

Only `offset` changes (page 3 at 10 rows → offset 20):

```html
<span data-role="page-link">
  <input type="hidden" name="offset" value="20"/>
  <a href="#"
     hx-get="/occurrence/tablePartial"
     hx-target="#occurrence-table"
     hx-swap="outerHTML"
     hx-include="#occurrence-table-state, [data-role='carry-through-state-params'], closest [data-role='page-link']">
    3
  </a>
</span>
```

Effective request params:

- From `#occurrence-table-state`: `id`, `partial`
- From carry-through: `limit`, `offset`, `sortBy`, `sortDir` (current values)
- From `page-link`: `offset=20` (overrides carry-through for this click)

### Example: sort by scientific name (first click)

Resets to the first page and changes sort:

```html
<span data-role="sort-link">
  <input type="hidden" name="offset"  value="0"/>
  <input type="hidden" name="sortBy"  value="scientificName"/>
  <input type="hidden" name="sortDir" value="asc"/>
  <span hx-get="/occurrence/tablePartial"
        hx-target="#occurrence-table"
        hx-swap="outerHTML"
        hx-include="#occurrence-table-state, [data-role='carry-through-state-params'], closest [data-role='sort-link']">
    Scientific Name <span class="sort-icon">↕</span>
  </span>
</span>
```

Effective request params:

- Identity: `id`, `partial`
- Carry-through: previous `limit`, `sortBy`, `sortDir`, …
- `sort-link`: `offset=0`, `sortBy=scientificName`, `sortDir=asc`

The partial binds the merged params, runs the query, and re-renders carry-through
with the new values so the next click starts from the updated state.

## Wiring controls

Defaults for fragment controls:

- **`hx-get`**: partial URL only (from `partial` in identity state, or a
  server-rendered equivalent). Do not append query strings in the GSP.
- **`hx-target`**: `#<id>` from identity state.
- **`hx-swap`**: usually `outerHTML` on the fragment root.
- **`hx-include`**: identity + carry-through + `closest [data-role='<action>']`
  (and `closest form` when the control is inside a form that carries overrides,
  e.g. page-size `<select>`).

Example include list for a page link:

```text
#occurrence-table-state, [data-role='carry-through-state-params'], closest [data-role='page-link']
```

## Reference implementation

**Plugin:** `nbn-components-plugin/grails-app/views/simpleDataTable/_table.gsp`

**Host example:** occurrence browse — `OccurrenceController#tablePartial` binds
`SimpleDataTableCommand`; the host adapts to `OccurrenceSearchCommand`.

Read the plugin template for pagination (`data-role="page-link"`, etc.). Sort
headers should follow the same scope pattern with `data-role="sort-link"` (not
`hx-vals` or hidden inputs loose inside `<th>` without an action wrapper).

## Avoid

- Query strings built in the GSP (`createLink(params: …)` on every sort/page link)
- `hx-vals` with hand-built JSON for params that belong in hidden inputs
- Putting identity fields (`id`, `partial`) in carry-through or action wrappers
- One generic `data-role` for everything — use **carry-through** for shared
  state and **named action roles** for per-click overrides
