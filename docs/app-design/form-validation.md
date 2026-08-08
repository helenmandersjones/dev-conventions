# Form Validation Framework

## Principle

Write validation logic once. Business logic validation lives on the server. Only trivial, stateless rules run on the client.

See also: [HTMX Patterns](htmx-patterns.md), [Form Validation UI](../conventions/form-validation-ui.md)

**Live demo:** run `./gradlew bootRun` in `nbn-components-plugin`, then open [Form handling demo](http://localhost:8765/demos/formHandlingDemo/index) — command-object create form with Bootstrap client validation, HTMX blur uniqueness check, and service-owned entity construction. Source: `nbn-components-plugin` → `FormHandlingDemoController`, `CreateDemoItemCommand`, `FormHandlingDemoService`.

## Two-tier approach

### Tier 1 — Bootstrap client-side (trivial, stateless rules)

Use Bootstrap 5's built-in validation. Apply `novalidate` to the `<form>`, then on submit add the `was-validated` class to trigger visual feedback.

Rules suited for client-side:
- Required fields (`required` attribute)
- Email format (`type="email"`)
- Password minimum length (`minlength`)
- Field length limits (`maxlength`)

```html
<form id="myForm" novalidate>
  <input type="email" name="email" required class="form-control">
  <div class="invalid-feedback">Please enter a valid email address.</div>
  <button type="submit">Save</button>
</form>

<script>
  document.getElementById('myForm').addEventListener('submit', function(e) {
    if (!this.checkValidity()) {
      e.preventDefault();
      e.stopPropagation();
    }
    this.classList.add('was-validated');
  });
</script>
```

### Tier 2 — HTMX server-side (business logic rules)

Use HTMX `hx-trigger="blur"` on fields that require a server/DB check. The server returns a small HTML fragment containing either an error or a success indicator. HTMX swaps it into a dedicated `<div>` next to the field.

Rules suited for server-side:
- Email uniqueness
- Username availability
- Foreign key existence (e.g. org exists)
- Any rule that requires DB state

```html
<input type="email" name="email" class="form-control"
       hx-post="/system/user/validateEmail"
       hx-trigger="blur"
       hx-target="#email-validation"
       hx-swap="innerHTML">
<div id="email-validation"></div>
```

The server action returns one of:
```html
<!-- valid -->
<span class="text-success small">Email is available.</span>

<!-- invalid -->
<span class="invalid-feedback d-block">An account with this email already exists.</span>
```

## Decision guide

| Rule type | Example | Where |
|-----------|---------|--------|
| Required field | Name cannot be blank | Bootstrap client |
| Format check | Valid email syntax | Bootstrap client |
| Length limit | Max 255 chars | Bootstrap client |
| Uniqueness | Email not already taken | HTMX server |
| Referential integrity | Org must exist | HTMX server |
| Business rule | User must have at least one role | HTMX server |

## What to avoid

- Do not duplicate business logic in both client JS and server code.
- Do not use a separate JS validation library (Parsley, etc.) — Bootstrap + HTMX is sufficient.
- Do not show HTMX validation errors before the user has interacted with a field.
