# CLAUDE.md

Project-scoped context for Claude Code and AGENTS.md-aware runtimes. Claude Code reads this file from `.claude/` directly; the root `AGENTS.md` symlink points here for other runtimes.

## What this repository is

A Terraform module for AWS Application Load Balancer (ALB), maintained by SUDO Consultants. Creates and manages ALBs, target groups, HTTP/HTTPS listeners, and listener rules with path- and host-based routing. Designed to work with ECS Fargate services using IP-based target groups.

## Git workflow (non-negotiable)

- Never commit to `main` or `master`. Create a feature branch for every task.
- Commit messages follow Conventional Commits: `feat:`, `fix:`, `docs:`, `chore:`, `refactor:`, `test:`, `ci:`, `perf:`, `build:`, `revert:`. Use `feat!:` or `fix!:` for breaking changes.
- Do not amend or force-push shared branches.
- Never edit files under `.terraform/` or commit `*.tfstate` or `.terraform.lock.hcl`.

## How to validate

```text
make fmt        # terraform fmt -recursive
make lint       # tflint --config=.tflint.hcl
make checkov    # checkov security scan
make validate   # terraform init -backend=false && terraform validate
make docs       # regenerate README terraform-docs section
make pre-commit # all pre-commit hooks against all files
```

## Terraform conventions

All module conventions, version-floor guards, HCL patterns, and semver discipline live in `.claude/skills/terraform/SKILL.md`. Load it before writing or reviewing any Terraform in this repository.
