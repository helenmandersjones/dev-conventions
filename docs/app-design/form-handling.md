Always use command objects for HTTP request/form binding when a controller action accepts user input for create, update, workflow, search/filter, or other validated operations. Domain objects should not be constructed from params in controllers. Services should receive validated scalar values, DTOs, or domain-shaped arguments, and should own persistence concerns.

```
def createOrganisation() {
    [cmd: new CreateOrganisationCommand()]
}

def saveOrganisation(CreateOrganisationCommand cmd) {
    if (cmd.hasErrors()) {
        render view: 'createOrganisation', model: [cmd: cmd]
        return
    }

    Organisation organisation = systemAdminService.createOrganisation(cmd.name.trim())

    flash.message = 'Organisation created.'
    redirect action: 'createOrganisation'
}

```