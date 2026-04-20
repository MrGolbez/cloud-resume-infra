# Infrastructure as Code

This folder contains the first Bicep pass for the Azure Cloud Resume Challenge infrastructure.

The purpose of this section is to show the infrastructure behind the portfolio project in source control, not just in the Azure Portal. These modules can be reviewed by employers, used for drift detection, and extended into a full deployment workflow over time.

It models the current production architecture:

- Azure Storage static website for `martycrane.com`
- Azure Functions Flex Consumption plan
- Linux Python Function App
- Function deployment/runtime storage account
- Cosmos DB Table API account and `Counter` table
- Cloudflare DNS/CDN documented as external configuration

Cloudflare is not deployed by this Bicep template. The frontend GitHub Actions workflow uses `CLOUDFLARE_ZONE_ID` and `CLOUDFLARE_API_TOKEN` to purge cached frontend files after a successful Azure Storage upload.

## Files

- `main.bicep`: Entry point for resource-group scoped deployment
- `main.parameters.json`: Production parameter values matching the current deployed resource names
- `modules/static-site-storage.bicep`: Static website storage account and blob service configuration
- `modules/cosmos-table.bicep`: Cosmos DB Table API account and counter table
- `modules/function-app-flex.bicep`: Function runtime storage, Flex Consumption plan, Function App, and app settings

## Module Overview

### Static Site Storage

`modules/static-site-storage.bicep` defines the Azure Storage account that hosts the frontend static website. It enables static website hosting with `index.html` as both the index and 404 document.

### Cosmos DB Table API

`modules/cosmos-table.bicep` defines the Cosmos DB account with Table API and serverless capabilities, then creates the `Counter` table used by the visitor counter.

### Function App Flex

`modules/function-app-flex.bicep` defines the Function App runtime storage account, deployment package container, Flex Consumption plan, Linux Python Function App, and required app settings.

The module currently uses connection strings to match the existing Python implementation. A future hardening step can move the backend to managed identity and RBAC.

## Validate

Build the Bicep file locally:

```powershell
az bicep build --file infra/main.bicep
```

The local Bicep build currently completes without compiler errors.

Preview changes before applying anything:

```powershell
az deployment group what-if `
  --resource-group rg-cloudresume-prod `
  --template-file infra/main.bicep `
  --parameters infra/main.parameters.json
```

The first `what-if` was run with `--result-format ResourceIdOnly`. Azure reported the existing resources as deploy/update candidates, which is expected for the first pass because these resources were originally created manually. Review a full `what-if` carefully before applying the template to production.

## Suggested GitHub Actions Workflow

The first IaC workflow should validate and preview changes, not automatically deploy infrastructure.

Recommended pull request workflow:

1. Run `az bicep build --file infra/main.bicep`
2. Run `az deployment group what-if`
3. Review the proposed Azure changes in the workflow logs

Recommended manual workflow:

1. Run Bicep build
2. Run `what-if`
3. Deploy only when explicitly triggered and reviewed

## Deploy

Only deploy after reviewing `what-if` output:

```powershell
az deployment group create `
  --resource-group rg-cloudresume-prod `
  --template-file infra/main.bicep `
  --parameters infra/main.parameters.json
```

## Notes

- No secrets are stored in this folder.
- Function App connection strings are generated during deployment from Azure resource keys.
- The current Function App uses connection-string based storage and Cosmos DB access to match the existing Python implementation.
- A future hardening step can move the Function App to managed identity and RBAC for storage and Cosmos DB access.
- The Cloudflare zone, DNS records, SSL/TLS mode, and cache rules should be documented separately because they are outside Azure Resource Manager.
