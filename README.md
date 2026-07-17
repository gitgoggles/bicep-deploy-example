# bicep-deploy-example
This repo contains a basic dotnet 10 webapp, but it's main purpose is to demonstrate Infrastructure as Code (IaC). 

- Deployed app: [https://app-bicep-deploy-example-prod-dwxeo5jum5wcs.azurewebsites.net/](https://app-bicep-deploy-example-prod-dwxeo5jum5wcs.azurewebsites.net/)

## deployment
The workflows are set to manual dispatch for demonstration purposes, but will connect to Azure via OIDC (no stored secret) provision a resource group, a VM, package the main branch and deploy it to the VM.

## first run bootstrapping
The deployment process requires an app registration (from which you derive a client id) and a service principal (with which you grant permissions to), so I have a bash script to configure both via the azure-cli, along with setting up a federated credential for GitHub's OIDC. The script will output the client id, tenant id and subscription ids upon completion, which will need to be saved into the repo's env vars for use by the runners. These three values are identifiers, not secrets.
