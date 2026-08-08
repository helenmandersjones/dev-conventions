# Error Handling Framework

## Principle

Let exceptions bubble up. Avoid `try/catch` in controllers unless you are genuinely recovering from a specific condition. Grails and Spring handle the rest.

The controller shape is lean:

```
def saveUser(CreateUserCommand cmd) {
    Organisation organisation = Organisation.get(cmd.organisationId)

    if (cmd.hasErrors()) {
        render view: 'createUser', model: [cmd: cmd, organisation: organisation]
        return
    }

    CreatedUser created = systemAdminService.createUser(cmd.organisationId, cmd.normalizedEmail)

    flash.message = 'User created successfully. The temporary password is: ' + created.tempPassword
    flash.initialPassword = created.tempPassword
    redirect action: 'index'
}
```

The command carries the form rules:
```
class CreateUserCommand implements Validateable {
    String organisationId
    String email

    String getNormalizedEmail() {
        email?.trim()?.toLowerCase()
    }

    static constraints = {
        organisationId blank: false, validator: { value ->
            Organisation.exists(value) ?: 'organisation.notFound.message'
        }

        email blank: false, email: true, validator: { value, obj ->
            !User.findByEmail(obj.normalizedEmail) ?: 'user.email.unique.message'
        }
    }
}

```


The service should still defend itself, but exceptions are then for non-form paths or race/stale states:
```
@Transactional
CreatedUser createUser(String organisationId, String email) {
    Organisation organisation = Organisation.get(organisationId)
    if (!organisation) {
        throw new IllegalArgumentException("Organisation not found: ${organisationId}")
    }

    if (User.findByEmail(email)) {
        throw new IllegalStateException("User already exists: ${email}")
    }

    ...
    user.save(failOnError: true, flush: true)
}

```

For good UX, the important distinction is:

- **Before service call:** expected user-fixable problems become command errors and re-render the form.
- **Inside service:** impossible/stale/race failures throw and are handled centrally or fail loudly during development.
- **Per-controller catches:** only for a deliberately different local recovery path




Dont have try catch in the controller like this:
```
def saveUser(CreateUserCommand createUserCommand) {
	
	....

	try {
	
		CreatedUser created = systemAdminService.createUser(createUserCommand.organisationId, email)
		
		flash.message = 'User created successfully. The temporary password is: ' + created.tempPassword
		
		....		
		redirect action: 'success'
	
	} catch (ValidationException e) {
	
		render ....
	
	} catch (IllegalArgumentException e) {
		
		render view: .....
	
	}
}

```

Do this:
```
def saveUser(CreateUserCommand cmd) {
    Organisation organisation = Organisation.get(cmd.organisationId)

    if (cmd.hasErrors()) {
        render view: 'createUser', model: [cmd: cmd, organisation: organisation]
        return
    }

    CreatedUser created = systemAdminService.createUser(cmd.organisationId, cmd.normalizedEmail)

    flash.message = 'User created successfully. The temporary password is: ' + created.tempPassword
    flash.initialPassword = created.tempPassword
    redirect action: 'index'
}

```

See also: [HTMX Patterns](htmx-patterns.md)

## Three-tier model

### Tier 1 — Unhandled exceptions → error page

Any exception that is not explicitly caught propagates to Grails' default exception handler and renders `error.gsp` (HTTP 500). This is appropriate for unexpected failures: database connectivity issues, programming errors, truly unexpected states.

No action needed in controllers for this tier — it's the default.

In development, `error.gsp` shows a full stack trace. In production, it shows a generic message.

### Tier 2 — Expected errors on full-page requests → flash + redirect

For form submissions and actions that result in a full-page redirect, use Grails flash scope.

```groovy
// In controller action
flash.error = "An organisation with that name already exists."
redirect(action: 'create')
```

```html
<!-- In GSP view -->
<g:if test="${flash.error}">
  <div class="alert alert-danger">${flash.error}</div>
</g:if>
<g:if test="${flash.message}">
  <div class="alert alert-success">${flash.message}</div>
</g:if>
```

Use `flash.message` for success confirmations, `flash.error` for failures.

This is the Post-Redirect-Get pattern. Always redirect after a successful POST.

### Tier 3 — HTMX partial requests → toast via HX-Trigger

For HTMX requests, the server sets an `HX-Trigger` response header with a JSON payload. The existing `toast.js` system listens for these events and displays the appropriate toast notification.

```groovy
// In controller action handling an HTMX request
response.setHeader('HX-Trigger', '{"showErrorToast": "Something went wrong."}')
render(status: 422)
```

```groovy
// Success
response.setHeader('HX-Trigger', '{"showSuccessToast": "User created successfully."}')
```

The frontend `toast.js` listens for `showSuccessToast`, `showErrorToast`, `showWarningToast`, and `showInfoToast` events on the document.

## Decision guide

| Context | Mechanism |
|---------|-----------|
| Unexpected exception (any request type) | Bubble up → error.gsp |
| Validation failure on full-page form submit | flash.error + redirect |
| Success after full-page form submit | flash.message + redirect |
| Error during HTMX partial request | HX-Trigger + toast |
| Success during HTMX partial request | HX-Trigger + toast |

## What to avoid

- Do not wrap every controller action in `try/catch`.
- Do not render error details to the user in production (they go in logs).
- Do not use flash scope for HTMX requests — the flash message will appear on the next full-page load, not inline.
- Do not silently swallow exceptions.

## Logging errors

When an exception is caught deliberately (Tier 2 / Tier 3), log it at `WARN` or `ERROR` level before responding. Let the canonical request log capture the outcome. See `logging.md`.
