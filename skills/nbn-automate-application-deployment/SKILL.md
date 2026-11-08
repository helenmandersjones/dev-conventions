---
name: nbn-automate-application-deployment
description: >-
  Design or implement pragmatic application deployment automation using
  version-controlled scripts and thin Rundeck jobs. Use for Docker image builds,
  artifact-to-registry pipelines, Compose/EC2 environments, initialization,
  deployment, and operational job setup; not for broad platform engineering
  unless the user requests it.
---

# Automate application deployment

Read `docs/conventions/application-deployment-automation.md` in the project
when it is available.

## Establish the local shape

1. Inspect the application repositories, deployment repository, existing
   Dockerfiles, artifact publication, runtime configuration, and comparable
   operational scripts or Rundeck jobs.
2. Identify the actual operator, environment count, deployment frequency,
   persistent state, and existing team tools. Keep the solution proportional.
3. Preserve explicit project choices. Do not introduce a larger platform stack
   simply because it could automate the same task.

## Implement the executable workflow

- Put behavior in Bash or Python scripts under the deployment repository.
- Keep job-runner definitions thin and invoke version-controlled scripts by a
  stable absolute path on the selected node.
- Prefer no-input convention-based jobs for routine actions, such as building
  the latest published snapshot. Add optional version selection only when it
  becomes useful.
- Resolve and record exact artifacts, build immutable images, and report the
  complete registry reference.
- Protect persistent data, back up before migrations, and separate one-time
  initialization from ordinary deployments.
- Add `DRY_RUN` and deliberate `DEBUG` behavior for mutable scripts without
  leaking credentials through global shell tracing.

## Verify proportionately

Run cheap syntax, rendered-configuration, parser, and dry-run checks locally.
When the project uses Ansible, run `ansible-lint` and
`ansible-playbook --syntax-check` on changed playbooks and roles before other
verification steps.
Use the real QA registry and QA host as the integration environment unless the
user explicitly needs a separate test platform. Expect early Rundeck runs to
be part of establishing the job; make failures diagnosable and retries safe.

Do not push images, provision cloud resources, deploy, migrate, restore, or
delete data without authorization for that external action. Stop for missing
credentials and decisions that materially affect security, cost, or retained
data; otherwise carry the requested workflow through implementation and
verification.
