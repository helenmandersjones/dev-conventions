# HTMX Patterns

## Principle

Keep interactions server-driven. Use HTMX for partial updates and events, not for rebuilding SPA-style client state.

## Core patterns

### 1) Form fragment + server validation rerender

Render a form fragment into a container, submit via HTMX, and rerender the same fragment on validation errors.

```html
<div id="userFormContainer"></div>
<button hx-get="/admin/user/formPartial" hx-target="#userFormContainer" hx-swap="innerHTML">
  Create user
</button>
```

```groovy
if (cmd.hasErrors()) {
    render template: 'form', model: [cmd: cmd]
    return
}
```

### 2) Success via `HX-Trigger` (not inline JS)

On successful HTMX POST, return `HX-Trigger` JSON and an empty body.

```groovy
response.setHeader('HX-Trigger', JsonOutput.toJson([
    userSaved: [id: user.id.toString(), name: user.name, message: 'User saved.']
]))
render ''
```

Use `JsonOutput.toJson(...)`; do not hand-build JSON strings.

### 3) Refresh list partial from event

Keep list/table in a dedicated container that refetches on a domain event.

```html
<div id="userListContainer"
     hx-get="/admin/user/listPartial"
     hx-trigger="userSaved from:body"
     hx-swap="innerHTML">
  <g:render template="userList" model="[users: users]"/>
</div>
```

`from:body` is important because `HX-Trigger` events bubble and are commonly observed from `body`.

### Endpoint naming convention

Use controller action names to describe response shape without encoding transport concerns in URL prefixes:

- Fragment-only actions use a `Partial` suffix (`formPartial`, `listPartial`).
- Full-page actions use unsuffixed domain names (`index`, `show`, `edit`).
- Reserve neutral unsuffixed names for endpoints that intentionally serve both full and partial responses based on request context.

### 4) Reuse same event in multiple contexts

Use one event name (for example `userSaved`) for both:
- standalone admin page list refresh
- modal/wizard listeners that update local UI

```js
document.body.addEventListener('userSaved', function (evt) {
  const d = evt.detail;
  if (!d || !d.id) return;
  // e.g. append new option, close modal, etc.
});
```

### 5) Toasts from events and HTMX errors

For success, listen to domain events and show toasts.

```js
document.body.addEventListener('userSaved', function (evt) {
  const d = evt.detail;
  if (d && d.message && window.showSuccessToast) {
    window.showSuccessToast(d.message);
  }
});
```

For server failures on HTMX requests, handle `htmx:responseError` once in layout.

```js
document.body.addEventListener('htmx:responseError', function (event) {
  const xhr = event.detail.xhr;
  let text = xhr.status + ' ' + (xhr.statusText || '');
  const ct = (xhr.getResponseHeader('Content-Type') || '').toLowerCase();
  if (ct.includes('application/json') && xhr.responseText) {
    try {
      const body = JSON.parse(xhr.responseText);
      text = body.error ? (xhr.status + ': ' + body.error) : text;
    } catch (e) { /* keep fallback text */ }
  }
  if (window.showErrorToast) window.showErrorToast(text, 'Server error');
});
```

## Controller response rule of thumb

- HTMX success: `HX-Trigger` + `render ''`
- HTMX validation error: rerender fragment with errors
- Non-HTMX success: `flash.message` + redirect (PRG)

## What to avoid

- Returning `HX-Redirect` for every HTMX success when a partial refresh is enough
- Mixing many one-off event names for the same domain action
- Building `HX-Trigger` JSON by string concatenation
- Using flash messages as the primary HTMX feedback channel
