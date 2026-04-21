# Cloud Resume Infrastructure

Bicep Infrastructure as Code for my Azure Cloud Resume Challenge portfolio project.

Live site:

```text
https://martycrane.com
```

Related repositories:

- Frontend static site: `https://github.com/MrGolbez/frontend-website`
- Backend Azure Function API: `https://github.com/MrGolbez/backend-api`

## Project Summary

This repo models the Azure infrastructure behind my Cloud Resume Challenge project. The application itself is already deployed, so the current purpose of this repo is to make the infrastructure reviewable, reproducible, and ready for future drift detection and controlled deployments.

Architecture:

```text
User
  -> Cloudflare DNS/CDN
  -> Azure Storage Static Website
  -> Browser JavaScript
  -> Azure Function HTTP API
  -> Cosmos DB Table API
```

Cloudflare DNS/CDN is documented as external configuration because it is not managed by Azure Resource Manager. The frontend repo handles Cloudflare cache purge through GitHub Actions.

## What This Demonstrates

- Bicep over raw ARM templates
- Modular Infrastructure as Code
- Azure Storage static website configuration
- Azure Functions Flex Consumption infrastructure
- Linux Python Function App configuration
- Function runtime and deployment storage
- Cosmos DB Table API account and table provisioning
- Production parameterization for existing resources
- Safe validation workflow using Bicep build and Azure `what-if`

## Repository Structure

```text
infra/
  main.bicep
  main.parameters.json
  modules/
    static-site-storage.bicep
    cosmos-table.bicep
    function-app-flex.bicep
  README.md
```

## Bicep Modules

### Static Site Storage

`infra/modules/static-site-storage.bicep` defines the Azure Storage account that hosts the static website and enables static website hosting with `index.html`.

### Cosmos DB Table API

`infra/modules/cosmos-table.bicep` defines the Cosmos DB account with Table API and serverless capabilities, then creates the `Counter` table used by the visitor counter.

### Function App Flex

`infra/modules/function-app-flex.bicep` defines:

- Function runtime storage account
- Deployment package blob container
- Azure Functions Flex Consumption plan
- Linux Python Function App
- Required app settings

The current implementation uses connection strings to match the existing Python backend. A future hardening step can move backend access to managed identity and RBAC.

## Validation

Build the Bicep:

```powershell
az bicep build --file infra/main.bicep
```

Preview Azure changes without deploying:

```powershell
az deployment group what-if `
  --resource-group rg-cloudresume-prod `
  --template-file infra/main.bicep `
  --parameters infra/main.parameters.json
```

The first `what-if` was run against the existing production resource group. Azure reported the existing resources as deploy/update candidates, which is expected for a first IaC pass over manually created resources. A detailed `what-if` should be reviewed before applying the template.

## Deployment

Only deploy after reviewing the full `what-if` output:

```powershell
az deployment group create `
  --resource-group rg-cloudresume-prod `
  --template-file infra/main.bicep `
  --parameters infra/main.parameters.json
```

## Suggested GitHub Actions Workflow

The first workflow for this repo should validate and preview infrastructure changes, not deploy automatically.

Recommended pull request workflow:

1. Run `az bicep build --file infra/main.bicep`
2. Run `az deployment group what-if`
3. Review proposed changes in the workflow logs

Recommended manual workflow:

1. Run Bicep build
2. Run `what-if`
3. Deploy only if explicitly triggered and reviewed

## Current Status

Core Cloud Resume Challenge: complete.

Infrastructure repo status:

- Initial Bicep modules created
- Production resource names mapped in `main.parameters.json`
- Bicep build validated locally
- Initial Azure `what-if` preview completed
- Production deployment intentionally not applied yet

Security challenge status:

- Phase 1 supply-chain baseline completed in `security/supply-chain-baseline.md`
- Secret scanning and push protection verified as enabled across the project repos
- Branch protection, signed commits, Dependabot, CodeQL, SBOM, and Grype are documented as next-phase controls

Next improvements:

- Complete signed commits and branch protection
- Add GitHub Actions validation for Bicep build and Azure `what-if`
- Add architecture diagram and screenshots
- Document Cloudflare DNS, SSL/TLS mode, cache rules, and token scope
- Tune Bicep against detailed `what-if` output
- Explore managed identity and RBAC for backend access
