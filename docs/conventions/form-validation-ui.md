# Form Validation UI Pattern (Bootstrap + Grails)

This project standardizes form validation behavior using the same pattern as the
form handling demo.

**Reference demo:** [Form handling demo](http://localhost:8765/demos/formHandlingDemo/index) in `nbn-components-plugin` (`./gradlew bootRun` on port 8765). Agents should copy this pattern for new forms unless a local feature has a documented reason to differ.

## Goal

Show validation failures clearly at two levels:

- A top summary alert for global/domain/service errors.
- Field-level inline errors under each input.

Preserve submitted values by re-rendering the form with the original command object.

## Binding boundary

Use command objects as the HTTP form/request boundary for controller actions
that accept user input for create, update, workflow, search/filter, or other
validated operations.

- The GET action creates the command object for the form model.
- The POST action accepts the command object as an action parameter, letting
  Grails bind and validate it.
- Controllers do not construct domain objects directly from `params`.
- Services receive validated scalar values, DTOs, or other domain-shaped
  arguments, and own persistence/domain construction.

Domain objects can still appear in the model when useful for display or for
service/domain validation errors, but the submitted form state should be held
by `cmd`.

## Validation boundary

Use three validation layers deliberately:

1. **Native HTML validation** for rules the browser supports declaratively:
   `required`, `maxlength`, `minlength`, `pattern`, `type="email"`, number
   ranges, required selects, required radio groups, and a single required
   checkbox.
2. **Command-object validation** for cheap local form rules: blank/null checks,
   sizes, simple formats, enum/list membership, and local cross-field checks.
3. **Controller/service validation** for checks that need a service, database,
   permissions, or current system state. Add user-correctable failures to
   `cmd.errors`, then re-render the same form.

Do not put service calls or database access inside command-object constraints.
The command object is the binding and cheap-validation boundary, not a service
locator. Final business invariants still belong in the service/domain/database;
the form check exists to give the user a clear correction path.

Checkbox rules:

- A single checkbox can be `required` when that exact checkbox must be checked
  (for example, accepting terms or confirming a declaration).
- A checkbox group rule such as "select at least one feature" is not a native
  HTML constraint. Keep that rule server-side in the command object and show
  the returned server error. Do not add custom JavaScript just to duplicate
  that rule.

## Controller Pattern

1. Bind request to a command object with `constraints`.
2. If `cmd.hasErrors()`, render the form view/partial with `cmd`.
3. Run any service-backed user-correctable checks and add failures to
   `cmd.errors`.
4. Perform service/domain work.
5. If a deliberate service result reports user-correctable failures, render the
   form with `cmd` and `result`.
6. On success, set flash success and redirect, or return the success fragment.

Expected, user-correctable form problems should be represented on the command
object before the create/update service call. For local checks, use command
constraints. For service-backed checks, ask the service from the controller and
add a command error with `cmd.errors.rejectValue(...)`. Do not rely on
per-action `try/catch` blocks around services to convert ordinary form
validation failures into field errors. If a service throws
`ValidationException`, `IllegalArgumentException`, or `IllegalStateException`
after command validation has passed, treat that as an exceptional/stale/invariant
failure and let it bubble to central error handling unless the action has a
genuinely different local recovery path.

Example shape:

```groovy
def saveThing(CreateThingCommand cmd) {
    if (cmd.hasErrors()) {
        render view: 'createThing', model: [cmd: cmd]
        return
    }

    if (thingService.nameTaken(cmd.normalizedName)) {
        cmd.errors.rejectValue('name', 'createThingCommand.name.taken.message', null, null)
        render view: 'createThing', model: [cmd: cmd]
        return
    }

    CreateThingResult result = thingService.create(cmd.toInput())
    if (result.hasErrors()) {
        render view: 'createThing', model: [cmd: cmd, result: result]
        return
    }

    flash.message = 'Thing created.'
    redirect action: 'index'
}
```

## GSP Pattern

### 1) Summary alert (global errors)

- Use `<components:formServerSideNonFieldErrors bean="${cmd}"/>`.
- Render domain errors from `result` if present.
- Render service failure enum/messages if present.

### 2) Field-level errors

- Keep Bootstrap inputs/selects/checks (`form-control`, `form-select`,
  `form-check-input`).
- Add `<components:formServerSideErrorClass>` inside the control class
  attribute so server-side errors get the custom `nbn-server-invalid` styling.
  Do not use Bootstrap's `is-invalid` for server errors because it also reveals
  sibling client-side `.invalid-feedback` blocks.
- Put `<components:formClientSideError>` directly after controls that use
  native HTML validation.
- Put `<components:formServerSideError>` directly after the same field/control
  group for command/server validation errors.

Example shape:

```gsp
<input type="text"
       name="label"
       value="${cmd?.label?.encodeAsHTML()}"
       class='form-control <components:formServerSideErrorClass bean="${cmd}" field="label"/>'
       required
       maxlength="100"/>
<components:formClientSideError label="Enter a label."/>
<components:formServerSideError bean="${cmd}" field="label"/>
```

The server-side error message uses `d-block`, so it displays without relying on
Bootstrap's `.is-invalid ~ .invalid-feedback` sibling selector. This keeps the
client-side and server-side feedback blocks independent and prevents duplicate
messages after server validation failures.

For server-only rules, omit the client-side error tag and render only the
server-side error:

```gsp
<fieldset class="mb-3">
    ...
    <input class='form-check-input <components:formServerSideErrorClass bean="${cmd}" field="features"/>'
           type="checkbox"
           name="features"
           value="notify"/>
    <components:formServerSideError bean="${cmd}" field="features"/>
</fieldset>
```

### 3) Form-level client validation hook

For normal HTMX forms, use native browser validation where it is supported and
Bootstrap's invalid styling:

```gsp
<form class="needs-validation"
      novalidate
      hx-validate="true"
      hx-post="${createLink(action: 'save')}"
      hx-target="#form-container"
      hx-swap="innerHTML">
```

Include the shared validation styles once on the page or layout:

```gsp
<components:formValidationStyles/>
```

For client-side validation, also include the script asset:

```gsp
<components:formValidationScripts/>
```

The styles include server-side invalid control styling and suppress Bootstrap's
green valid-state styling. The script only reveals invalid native constraints.
It also clears stale server-side styling/messages for a field when the user
edits that field. It must not contain form-specific validation rules.

To temporarily verify server-side validation rendering, remove
`hx-validate="true"` and comment out `<components:formValidationScripts/>`.
Leave `<components:formValidationStyles/>`, the HTML attributes, and command
constraints in place.

## Messages

Every command object that backs a user-facing form should have user-facing
messages in `grails-app/i18n/messages.properties`. Keep them in a clearly
labeled block for the form.

Use field-specific keys first:

```properties
# Create thing form
createThingCommand.name.nullable.error=Enter a name.
createThingCommand.name.blank.error=Enter a name.
createThingCommand.name.maxSize.error=Name must be 100 characters or fewer.
createThingCommand.category.inList.error=Select a valid category.
createThingCommand.acceptTerms.validator.error=Confirm the terms.
createThingCommand.name.taken.message=This name is already taken.
```

Define both `nullable` and `blank` messages for required text fields because an
omitted field and a submitted empty field can produce different constraint
codes. Built-in Grails constraints use the `.error` suffix, for example
`createThingCommand.name.blank.error`. Custom codes passed directly to
`rejectValue(...)` or returned from validators should match the code exactly.
Avoid relying on the Grails default messages for polished forms; they are
implementation-focused and expose class/property names.

## HTMX Adaptation

For HTMX forms, keep the same validation rules and rendering pattern, but return fragments:

- Initial page returns a container + trigger.
- `GET` form endpoint returns only the form fragment.
- `POST` save endpoint:
  - on validation failure: re-render the same form fragment with `cmd`/`result` (HTTP 200 is fine for swap).
  - on success: return success fragment (or updated list fragment) to swap target.
  - on bubbled exceptions: let central error handling return the appropriate
    HTMX error response (for example a toast trigger or small error fragment)
    with an error status.

Use the same Bootstrap classes in fragments so validation visuals are consistent with full-page forms.

For full-page requests, bubbled exceptions should be handled by the central
error page/error controller path. Keep form actions focused on the normal
form UX: command errors re-render the form; exceptional failures leave the
form action and are handled consistently for the whole app.

## HTMX endpoint naming

Use action names that make the response shape obvious for fragment-only endpoints:

- Fragment-only `GET` actions should use the `Partial` suffix (for example `formPartial`, `listPartial`).
- Keep full-page actions unsuffixed (for example `index`, `show`).
- If an endpoint is intended to support both full-page and fragment responses, use a neutral unsuffixed action name and branch on request context rather than forcing a `Partial` name.

## Why this pattern

- Users see both broad and specific errors.
- No lost input after validation errors.
- Works for full-page forms and HTMX componentized forms with minimal divergence.
