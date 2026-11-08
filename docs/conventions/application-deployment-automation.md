# Application Deployment Automation

## Aim

Make deployment automation repeatable and understandable without giving a
small application the operational machinery of a large platform. Start from
the application's actual scale, ownership, release frequency, and existing
team tools.

## Ownership and Shape

- Keep application image definitions with the application unless an existing
  deployment repository clearly owns them.
- Keep cross-service runtime configuration and deployment scripts in the
  deployment repository.
- Put operational behavior in version-controlled Bash or Python scripts that
  can be run without Rundeck.
- Keep Rundeck jobs thin: select a node, collect the few necessary options,
  provide credentials and permissions, invoke an absolute script path, and
  retain logs.
- Ensure the complete repository checkout is available when an entry script
  uses sibling scripts or configuration. Do not copy only the entry script to
  a temporary node and expect relative dependencies to exist.

Do not introduce CDK, Ansible, Kubernetes, a local Rundeck installation, cloud
mocks, or another platform layer solely for theoretical completeness. Use such
tools when the project already uses them or when repeated infrastructure work
justifies them.

## Artifact-to-Image Builds

Build deployable images from the selected published artifact rather than an
arbitrary developer checkout. A normal build job should:

1. Resolve the artifact using the repository's established coordinates.
2. Record the exact resolved version, especially for timestamped snapshots.
3. Download it into a temporary Docker build context.
4. Build with the application's Dockerfile.
5. Tag the image immutably with enough identity to reproduce the selection.
6. Push it to the approved registry and report the complete image reference.

Prefer convention over configuration. If the routine action is "build the
latest snapshot", make that a no-input job. Add "build a specific version"
only when there is a demonstrated need. Never use a reusable snapshot or
`latest` tag in an immutable registry.

## Runtime and Persistent Data

- Keep persistent database and application data outside disposable containers.
- Use stable numeric UID/GID values where bind-mounted files must be writable.
- Back up persistent databases before schema migrations.
- Run migrations from the exact selected application version, not an unrelated
  source checkout on the target host.
- Separate one-time initialization from ordinary repeatable deployments.
- Make normal deployments safe to retry and avoid volume-deleting commands.

## Diagnostics

Scripts that perform external mutations should normally support:

- `DRY_RUN=true`: validate and print the planned operations without mutating
  Docker, cloud resources, files, or databases.
- `DEBUG=true`: add useful non-secret paths, resolved versions, image names,
  commands, health attempts, and response status.

Do not use global `set -x` where scripts can see passwords, tokens, or other
credentials. Redact secrets explicitly. On failure, print bounded diagnostics
such as service status and the tail of relevant logs. When temporary build
contexts matter for diagnosis, support retaining them only on request or
failure.

## Testing Progression

Use the smallest progression that gives useful confidence:

1. Run syntax, formatting, configuration-rendering, and dry-run checks
   locally. Where a project already uses Ansible, this includes `ansible-lint`
   and `ansible-playbook --syntax-check` on changed playbooks and roles.
2. Run individual scripts directly where practical.
3. Invoke the same scripts through Rundeck with dry-run enabled.
4. Execute against the real QA registry and QA host.
5. Promote the proven scripts and immutable images toward production with the
   necessary approvals.

QA is normally the integration environment. Do not build local AWS or Rundeck
mocks by default; they often test the mock rather than IAM, networking, storage,
and execution behavior that can fail in the real environment.

## Authorization and Safety

Repository edits and local read-only checks do not imply permission to create
cloud resources, push images, alter a database, deploy, restore, or delete
data. Confirm the target and obtain required authorization immediately before
material external changes. Keep production build and deployment decisions
separate when the release process requires an approval boundary.
