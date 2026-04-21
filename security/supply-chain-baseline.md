# Supply Chain Security Baseline

This document captures the current software supply chain for the Azure Cloud Resume Challenge project before adding the dedicated security controls from the "Securing Your Software Supply Chain" challenge.

The goal of Phase 1 is to understand how code moves from local development to production, where trust boundaries exist, which controls already exist, and which risks should be addressed next.

## Repositories In Scope

| Repository | Purpose | Default branch | Visibility | Current workflow surface |
| --- | --- | --- | --- | --- |
| `MrGolbez/frontend-website` | Static resume site, blog page, visitor counter JavaScript, frontend deployment workflow | `master` | Public | `Frontend Deploy` |
| `MrGolbez/backend-api` | Python Azure Function visitor counter API and tests | `master` | Public | `Backend Tests` |
| `MrGolbez/cloud-resume-infra` | Bicep Infrastructure as Code modules and project architecture documentation | `main` | Public | No workflow yet |

## Current Production Flow

```text
Developer workstation
  -> Git commit
  -> GitHub repository
  -> GitHub Actions
  -> Azure deployment target
  -> Cloudflare cache purge
  -> Public website and API
```

Runtime request path:

```text
Visitor
  -> Cloudflare DNS/CDN
  -> Azure Storage Static Website
  -> Browser JavaScript fetch()
  -> Azure Function HTTP API
  -> Cosmos DB Table API
```

## Repository Details

### Frontend

Repository:

```text
https://github.com/MrGolbez/frontend-website
```

Deployment workflow:

```text
.github/workflows/frontend-deploy.yml
```

Observed workflow controls:

- Runs on pushes to `master` or `main` when frontend files change.
- Supports manual `workflow_dispatch`.
- Uses explicit workflow permissions:
  - `id-token: write`
  - `contents: read`
- Uses Azure OpenID Connect through `azure/login`.
- Uploads static files to Azure Storage `$web`.
- Purges Cloudflare cache after deployment.
- Uses concurrency control to cancel stale deploy runs.

GitHub Actions secret names in use:

- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `CLOUDFLARE_API_TOKEN`

GitHub Actions variable names in use:

- `CLOUDFLARE_ZONE_ID`

Known deployment targets:

- Azure Storage static website account: `martycraneresume26`
- Public site: `https://martycrane.com`
- Cloudflare cache purge API

Recent validation:

- Recent frontend deployment runs completed successfully.
- Earlier Azure OIDC login failure was resolved by matching the GitHub OIDC subject claim to the Azure federated credential.

### Backend

Repository:

```text
https://github.com/MrGolbez/backend-api
```

Observed workflow:

```text
.github/workflows/backend-tests.yml
```

Observed workflow controls:

- Runs on pushes to `main`.
- Runs on pull requests to `main`.
- Supports manual `workflow_dispatch`.
- Checks out code.
- Sets up Python 3.13.
- Installs dependencies from `requirements.txt`.
- Runs `pytest`.

Current dependency file:

```text
requirements.txt
```

Observed Python dependencies:

- `azure-functions`
- `azure-data-tables==12.6.0`
- `pytest`

Known runtime targets:

- Azure Function App: `martycrane-resume-api`
- Cosmos DB Table API account: `martycrane-resume-db`
- Table: `Counter`

Verification note:

- The repository currently exposes a backend test workflow locally and through GitHub.
- No backend repository-level Actions secrets or variables were observed through GitHub CLI during this baseline pass.
- If backend deployment is automated outside the visible workflow, that path should be documented before later security phases.

### Infrastructure

Repository:

```text
https://github.com/MrGolbez/cloud-resume-infra
```

Current IaC scope:

- Azure Storage static website
- Cosmos DB Table API account
- `Counter` table
- Azure Functions Flex Consumption plan
- Linux Python Function App
- Function runtime/deployment storage account

Current validation state:

- `az bicep build --file infra/main.bicep` completed successfully.
- Initial Azure `what-if` was run in resource ID format.
- Production deployment from Bicep has not been applied yet.

Workflow status:

- No GitHub Actions workflow exists yet for this repo.
- Planned next control: Bicep build and Azure `what-if` validation workflow.

## Current GitHub Security Settings

Observed across all three repositories:

- Repositories are public.
- Secret scanning is enabled.
- Secret scanning push protection is enabled.
- Dependabot security updates are disabled.
- Branch protection is not currently enabled on default branches.
- Latest checked commits were unsigned.

Phase 2 and Phase 3 will address these gaps.

## Trust Boundaries

### Developer Workstation

The local machine is where code changes, dependency updates, and commits originate.

Risks:

- Compromised local machine
- Unsigned commits
- Accidental secret exposure before push protection catches it
- Unreviewed direct pushes

Controls already present:

- GitHub secret scanning push protection is enabled remotely.

Planned controls:

- Signed commits
- Branch protection
- Pull request workflow for default branches

### GitHub Repositories

GitHub stores the source code, workflows, repository variables, and encrypted secrets.

Risks:

- Compromised GitHub account
- Over-permissioned workflows
- Malicious workflow changes
- Stale dependencies
- Unprotected default branches

Controls already present:

- Public repo visibility supports CodeQL and security scanning workflows.
- Frontend workflow uses explicit minimal permissions for deployment.
- Frontend deployment uses OIDC instead of a long-lived Azure client secret.

Planned controls:

- Repository rules or branch protection
- Required status checks
- Dependabot security updates
- CodeQL
- SBOM generation
- Grype dependency scanning

### GitHub Actions Runners

GitHub-hosted runners execute tests and deployments.

Risks:

- Malicious dependency install during CI
- Compromised third-party GitHub Action
- Secrets exposed to workflow steps
- Supply-chain attack through unpinned Actions

Controls already present:

- Frontend deployment uses repository secrets and variables.
- Frontend Azure authentication uses OIDC.
- Frontend Cloudflare token is exposed only to the purge step.

Planned controls:

- Pin or review third-party Actions
- Add explicit permissions to all workflows
- Add SBOM and vulnerability scanning
- Add CodeQL and scheduled scans

### Azure

Azure hosts the static site origin, serverless API, Cosmos DB Table API, and Function runtime storage.

Risks:

- Over-permissioned deployment identity
- Connection-string based backend access
- Manual configuration drift
- Production changes outside IaC

Controls already present:

- Frontend deployment uses Azure OIDC.
- Static website deployment identity uses Azure RBAC.
- Bicep modules now document the current infrastructure.

Planned controls:

- IaC `what-if` workflow
- Review role assignments
- Consider managed identity and RBAC for backend access

### Cloudflare

Cloudflare manages DNS/CDN and cache purge for the public site.

Risks:

- Cloudflare API token misuse
- DNS changes outside source control
- Cache rules not documented
- Cloudflare configuration drift

Controls already present:

- Cloudflare token is stored as a GitHub Actions secret.
- Cloudflare zone ID is stored as a GitHub Actions variable.
- Frontend workflow purges cache after deploy.

Planned controls:

- Document Cloudflare DNS records, SSL/TLS mode, cache rules, and token scope.
- Consider Terraform later for Cloudflare DNS/CDN management.

## Current Controls

| Control | Frontend | Backend | Infra |
| --- | --- | --- | --- |
| Public repository | Yes | Yes | Yes |
| GitHub Actions workflow | Yes | Yes | No |
| Secret scanning | Enabled | Enabled | Enabled |
| Push protection | Enabled | Enabled | Enabled |
| OIDC cloud auth | Yes | Not observed | Not yet needed |
| Branch protection | Not enabled | Not enabled | Not enabled |
| Signed commits | Not enabled | Not enabled | Not enabled |
| Dependabot security updates | Disabled | Disabled | Disabled |
| CodeQL | Not enabled | Not enabled | Not enabled |
| SBOM generation | Not enabled | Not enabled | Not applicable yet |
| Grype or second dependency scan | Not enabled | Not enabled | Not enabled |
| IaC validation workflow | Not applicable | Not applicable | Not enabled |

## Key Findings

1. The public project architecture is complete enough to support the security challenge.
2. Frontend deployment has the strongest current supply-chain posture because it uses OIDC, explicit workflow permissions, and Cloudflare purge automation.
3. Secret scanning and push protection are already enabled on all three repos.
4. Default branches are not protected yet.
5. Latest checked commits are unsigned.
6. Dependabot security updates are disabled.
7. CodeQL is not yet enabled.
8. Backend dependency inventory exists through `requirements.txt`, making it the best first target for SBOM and Grype scanning.
9. The infra repo does not yet have a validation workflow, so Bicep build and `what-if` should be added later.
10. Cloudflare configuration is operational but not yet fully documented as part of the security baseline.

## Phase 2 Targets

Next phase: Repository trust and commit integrity.

Planned work:

- Configure commit signing locally.
- Verify GitHub shows commits as `Verified`.
- Add branch protection or repository rules on:
  - `frontend-website:master`
  - `backend-api:master`
  - `cloud-resume-infra:main`
- Require pull requests or required status checks where practical.
- Document the policy in each repo.

## Blog Post 1 Inputs

Do not write the blog post yet. When ready, Blog Post 1 should explain:

- What a software supply chain is.
- Why a small cloud resume project still has a real supply chain.
- How code moves from local development to GitHub Actions, Azure, Cloudflare, and production.
- What trust boundaries exist.
- Which controls already existed before the security challenge.
- Which gaps were found in Phase 1.
- Why the next step is signed commits and branch protection.
