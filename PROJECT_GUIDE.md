# The Complete Guide to This Project
### (Written so anyone, even with zero background, can understand it)

This is the ninth and final "new concept" project in a portfolio
series. It assumes the basics from earlier guides (Git, GitHub,
Terraform, CI/CD, Lambda, API Gateway) are already familiar. This one
is entirely about **environments** — running the same thing multiple
times, safely, for different purposes.

---

## Part 1 — Why "just deploy once" isn't how real work actually goes

Every earlier project in this portfolio was deployed exactly once —
build it, verify it, done. Real software work almost never looks like
that. Changes get tested somewhere safe first (a **dev** or **staging**
environment), and only once they're confirmed working do they reach the
environment real users actually depend on (**prod**, short for
"production"). This project demonstrates that pattern for the first
time in this portfolio, using the simplest possible example (the same
small "hello" API) so the *mechanism* is the focus, not the app itself.

## Part 2 — The core idea: same code, different settings

The entire project is built around one principle: **never write the
same infrastructure code twice for different environments.** Instead,
one set of `.tf` files describes the *shape* of what gets built, and
small, separate files describe *how it should differ* per environment.

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "prod"], var.environment)
    error_message = "environment must be either \"dev\" or \"prod\"."
  }
}
```

This variable has **no default value** — it must always be explicitly
provided. The `validation` block is a genuinely new Terraform feature
for this portfolio: it runs a check *before* anything gets created. If
someone typed `"staging"` or `"Prod"` (wrong capitalization) by
mistake, Terraform stops immediately with a clear error message,
instead of silently creating a resource with a typo baked into its
name — a real problem once you have several real environments to keep
straight.

## Part 3 — The `.tfvars` files: where the actual differences live

```
# dev.tfvars
environment        = "dev"
lambda_memory_size = 128

# prod.tfvars
environment        = "prod"
lambda_memory_size = 256
```

Two small files, each setting the same two variables to different
values. Neither file contains any resource definitions — just values.
When Terraform runs with `-var-file=dev.tfvars`, every `var.environment`
and `var.lambda_memory_size` reference throughout `main.tf` resolves
to the `dev` values; point it at `prod.tfvars` instead, and the exact
same code produces the `prod` values. This is the actual mechanism
behind "same code, different environments" — not two copies of the
code, one small settings file per environment.

## Part 4 — Terraform workspaces: separate memory, same backend

Every earlier project used a unique S3 `key` per project to keep its
Terraform state (memory of what's been built) separate from every other
project. This project does something different: `dev` and `prod` share
the *same* backend configuration entirely:

```hcl
terraform {
  backend "s3" {
    bucket = "ralso11-terraform-state-2026"
    key    = "multi-env-project/terraform.tfstate"
  }
}
```

Instead, **Terraform workspaces** handle the separation:

```
terraform workspace select -or-create dev
terraform plan -var-file=dev.tfvars
```

`select -or-create` switches to a workspace named `dev` — creating it
automatically the very first time. Behind the scenes, Terraform stores
each workspace's state under its own sub-path inside that same S3
key (specifically `env:/dev/...` and `env:/prod/...`) — genuinely
separate memory, without needing separate top-level configuration.
This is *a* valid way to separate environments in Terraform (separate
`key` values per environment, as used in every earlier project, is
another equally valid approach) — workspaces are worth knowing because
they're commonly seen in real Terraform codebases and interview
questions specifically ask about the tradeoff between the two
approaches.

## Part 5 — The pipeline: one workflow, a dropdown, two outcomes

```yaml
on:
  workflow_dispatch:
    inputs:
      environment:
        type: choice
        options: [dev, prod]
```

This creates an actual **dropdown menu** in GitHub's "Run workflow"
button — instead of the environment being hardcoded, whoever triggers
the deployment chooses it right there.

```yaml
apply:
  environment: ${{ inputs.environment }}
  steps:
    - run: terraform workspace select -or-create ${{ inputs.environment }}
    - run: terraform apply -var-file=${{ inputs.environment }}.tfvars -auto-approve
```

Both the **GitHub Environment** used for approval rules and the
**Terraform workspace/tfvars file** used for the actual deployment are
driven by that same single dropdown choice — one input, fully
consistent behavior throughout the whole pipeline.

## Part 6 — Two GitHub Environments, two sets of rules

This is the piece that makes the demo *mean* something, not just
technically work: `dev` and `prod` were configured as **separate
GitHub Environments** with genuinely different protection rules —
`dev` has no required reviewers (fast, frictionless, appropriate for a
testing environment), while `prod` requires an explicit manual
approval every time, regardless of who or what triggers the pipeline.
This mirrors exactly how real companies protect production
environments differently from testing ones — the code path is
identical, but the *governance* around it isn't.

## Part 7 — Proof it's real, not just labeled differently

The Lambda function's response includes which environment it believes
it's running in:

```python
ENVIRONMENT = os.environ.get("ENVIRONMENT", "unknown")
```

Calling the `dev` URL returns `"environment": "dev"`; calling the
entirely separate `prod` URL (a different API Gateway, a different
Lambda function, a different IAM role — all with `-dev-` or `-prod-`
in their actual AWS resource names) returns `"environment": "prod"`.
This is the concrete proof that the two deployments are truly
independent resources, not the same thing with a different label
applied afterward.

## Part 8 — Command/concept glossary (new items vs previous projects)

| Term | Plain-language meaning |
|---|---|
| Environment (dev/staging/prod) | A separate, independent deployment of the same system, used for a different purpose (testing vs real users) |
| `.tfvars` file | A file supplying values for Terraform variables, without containing any resource definitions itself |
| `validation` block | A Terraform check that runs before resources are created, rejecting invalid variable values immediately |
| Terraform workspace | A named, isolated slice of state within one backend configuration — a way to separate environments without separate backend keys |
| `workflow_dispatch` input | A configurable field (like a dropdown) shown when manually triggering a GitHub Actions workflow |

## Part 9 — How to explain this project in an interview

> "I built a small API and deployed it as two genuinely separate
> environments, dev and prod, from the same Terraform code — using
> workspaces for state isolation and per-environment tfvars files for
> the actual configuration differences. The pipeline has a dropdown to
> choose which environment to deploy, and I set up different GitHub
> Environment protection rules for each: dev deploys freely for fast
> iteration, while prod always requires a manual approval, regardless
> of who triggers it. I proved the separation is real, not cosmetic, by
> having the API report which environment it's actually running in,
> and confirming dev and prod return different answers from genuinely
> different underlying AWS resources."

That story demonstrates real environment-management maturity — a
distinctly more senior concern than "I can deploy a working thing
once," and one that comes up constantly in real DevOps interviews.

---

*This document, together with the repo's README.md, covers everything
needed to fully understand, explain, and rebuild this project.*
