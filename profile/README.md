# FieldStack

**Unified commerce platform for retailers.**

FieldStack provides retailers with a complete suite of tools for store and web commerce operations — from point of sale and warehouse management to online storefronts and back-office administration.

## Engineering

Our engineering organization is structured around six business domains: **Booking**, **POS**, **Webstore**, **Warehouse**, **Back Office**, and **Infrastructure**. Each domain owns its bounded context, and we use a commitments-first execution model where work is explicitly owned and tracked.

## Standards

All repositories in this organization follow these practices:

- **Conventional Commits** — structured commit messages for automated changelogs and clear history
- - **Squash Merge** — clean, linear history on protected branches
  - - **CalVer Releases** — calendar-based versioning (e.g., `2026.3.1`)
    - - **Branch Protection** — required reviews, status checks, and up-to-date branches
      - - **Reusable Workflows** — shared CI/CD pipelines via the [.github](.github) repo
        - - **CLAUDE.md** — AI coding guardrails in every repository
          - - **OpenTofu** — infrastructure-as-code standard for all deployable services
           
            - ## Security
           
            - Please see our [Security Policy](https://github.com/FieldStackhq/.github/blob/main/SECURITY.md) for vulnerability reporting guidelines.
