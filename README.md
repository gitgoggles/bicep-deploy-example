# Bicep .NET Web API deployment example

This repository provisions a minimal Linux Azure App Service for a .NET 10 Web API and deploys it from GitHub Actions using OpenID Connect (OIDC).

## Architecture

The production Bicep deployment creates:

- Resource group `rg-bicep-deploy-example-prod-uks`
- Linux App Service Plan `asp-bicep-deploy-example-prod`
- Globally unique Linux Web App running the .NET 10 App Service stack

The Web App is public, HTTPS-only, and configured with FTP disabled and a minimum TLS version of 1.2. The initial App Service Plan uses the Free `F1` SKU.

> `F1` has daily compute quotas, no Always On support, shared infrastructure, and no production SLA. Change `appServicePlanSku` in `infra/main.bicepparam` and redeploy before using this for a real production workload.

## Repository layout

```text
.github/workflows/infrastructure.yml  Bicep validation and deployment
.github/workflows/application.yml     API build and deployment
infra/main.bicep                      Subscription-scope entry point
infra/application.bicep               App Service resources
infra/main.bicepparam                 Production parameters
infra/bootstrap.sh                    Entra application and OIDC bootstrap
src/Api/Api.csproj                    Expected API project (not included)
```

## Prerequisites

1. An Azure subscription.
2. An Entra application and service principal with Contributor access to the subscription.
3. A federated credential whose subject is:

   ```text
   repo:gitgoggles/bicep-deploy-example:ref:refs/heads/main
   ```

4. These GitHub repository variables:

   - `AZURE_CLIENT_ID`
   - `AZURE_TENANT_ID`
   - `AZURE_SUBSCRIPTION_ID`

`infra/bootstrap.sh` can create the Azure identity and federated credential and prints the required variable values. Run it while authenticated to the intended Azure subscription:

```bash
az login
az account set --subscription '<subscription-id>'
./infra/bootstrap.sh
```

The identifiers are repository variables, not secrets. OIDC avoids storing a client secret in GitHub.

## Application source

Create the .NET 10 API at the path expected by the application workflow:

```text
src/Api/Api.csproj
```

For example, you can scaffold it locally with:

```bash
dotnet new webapi --framework net10.0 --output src/Api
```

## Workflows

### Infrastructure

On pull requests that change `infra/**`, the infrastructure workflow compiles the Bicep template and parameter file without authenticating to Azure.

On a push to `main`, it:

1. Authenticates to Azure using OIDC.
2. previews changes with `az deployment sub what-if`;
3. performs an incremental subscription-scope deployment.

The stable deployment name is `bicep-deploy-example-prod`. The application workflow reads the Web App name from this deployment's outputs.

### Application

On pull requests that change `src/**`, the application workflow restores and publishes `src/Api/Api.csproj`.

On a push to `main`, it additionally:

1. authenticates to Azure using OIDC;
2. retrieves the Web App name from the Bicep deployment output;
3. deploys the published ZIP package with `azure/webapps-deploy`.

The infrastructure and application production jobs share a concurrency lock so they cannot modify production simultaneously.

## First deployment

Because the application workflow expects the Web App to exist, deploy in this order:

1. Run the **Infrastructure** workflow from `main`, or merge the infrastructure files to `main`.
2. Add the API under `src/Api` and push it to `main`.

Subsequent infrastructure and application changes deploy independently based on path filters. Both workflows can also be started manually from `main`.

## Environments and scaling

The Bicep templates are parameterized by environment, region, workload name, and App Service Plan SKU. Production values are in `infra/main.bicepparam`.

To scale the plan, update:

```bicep
param appServicePlanSku = 'B1'
```

and rerun the infrastructure deployment. Standard App Service tier changes update the existing plan in place, subject to Azure region and feature availability.

To add a development environment later, create a separate `.bicepparam` file, deployment name, workflow branch mapping, and matching federated credential.
