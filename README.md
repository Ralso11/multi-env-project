# Multi-Environment Project

**Live dev API:** https://z2at3jq2ul.execute-api.eu-central-1.amazonaws.com/hello
**Live prod API:** https://vty8l5c9a2.execute-api.eu-central-1.amazonaws.com/hello

📖 Want the full, beginner-friendly walkthrough of every step, command,
and decision made in this project? See
[PROJECT_GUIDE.md](./PROJECT_GUIDE.md).

## What is this project, in one sentence?

The same Lambda API code, deployed as two genuinely independent
environments (dev and prod) using Terraform workspaces and
per-environment settings — with `prod` requiring manual approval while
`dev` deploys freely.

## Why this project exists

The ninth project in this series, and the second of two focused
specifically on core DevOps practice rather than a new AWS service.
Every earlier project deployed exactly once, to one environment. Real
DevOps work almost always involves multiple environments — testing
changes safely in `dev` before they ever reach `prod`, which real users
depend on. This project demonstrates that pattern concretely, not just
in theory.

## How it works

```
Same code + same Terraform
        |
        +--> dev.tfvars  --> Terraform workspace "dev"  --> dev API (no approval needed)
        |
        +--> prod.tfvars --> Terraform workspace "prod" --> prod API (requires approval)
```

Calling each API's `/hello` route returns which environment it's
actually running in — proof the two deployments are genuinely separate,
not just cosmetically different.

## Key mechanisms

- **`environment` variable with a `validation` block** — Terraform
  rejects anything other than exactly `"dev"` or `"prod"` before
  creating anything, catching typos immediately.
- **Per-environment `.tfvars` files** (`dev.tfvars`, `prod.tfvars`) —
  small files setting environment-specific values (like Lambda memory
  size), without duplicating any actual resource code.
- **Terraform workspaces** — `terraform workspace select -or-create dev`
  gives each environment its own isolated state, even though both
  share the same S3 backend bucket and key.
- **A `workflow_dispatch` dropdown input** — lets you choose `dev` or
  `prod` directly in GitHub's UI when triggering a deployment.
- **Two separate GitHub Environments** (`dev`, `prod`) with different
  protection rules — `prod` requires a manual reviewer approval, `dev`
  does not, demonstrating real environment governance.

## Problems & fixes — quick reference

| Problem | Why it happened | How it was fixed |
|---|---|---|
| `terraform fmt -check` failed on the `.tfvars` files | Inconsistent spacing when typed into the terminal (same class of issue hit in earlier projects, this time in a new file type) | Recomputed exact alignment and rewrote both files |

## How to reproduce this project

1. Install Git and Terraform.
2. Create a GitHub repo, clone it locally.
3. Write a small app whose behavior visibly differs based on an
   environment variable, so you can prove two deployments are separate.
4. Add an `environment` variable with a `validation` block restricting
   it to known values.
5. Write two `.tfvars` files (one per environment) with the values
   that should differ.
6. Configure a shared S3 backend and use `terraform workspace
   select -or-create <env>` to give each environment isolated state.
7. Create two GitHub Environments with different protection rules.
8. Build a `workflow_dispatch` pipeline with a dropdown input choosing
   the environment, using it to select both the Terraform workspace
   and the GitHub Environment dynamically.
9. Deploy `dev`, verify it, deploy `prod` (approving when prompted),
   and confirm both report their own environment correctly.

## What's next (possible future additions)

- [ ] Add a `staging` environment as a third tier between dev and prod.
- [ ] Automatically promote a change from dev to prod only after a
      successful dev deployment, instead of choosing manually.
- [ ] Add environment-specific monitoring thresholds (e.g. prod alarms
      more sensitive than dev).
