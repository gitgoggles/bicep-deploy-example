# bicep-deploy-example
This repo contains a basic dotnet 10 webapp, but it's main purpose is to demonstrate Infrastructure as Code (IaC). 

These are hosted on an Azure free tier, so give them a minute to load.
- production: [https://app-bicep-deploy-example-production-lbtltblbbsg7w.azurewebsites.net/](https://app-bicep-deploy-example-production-lbtltblbbsg7w.azurewebsites.net/)
- staging: [https://app-bicep-deploy-example-staging-prbblykd2aiem.azurewebsites.net/](https://app-bicep-deploy-example-staging-prbblykd2aiem.azurewebsites.net/)

## deployment
The github workflows connect to Azure via OIDC (no stored secret), provision a resource group, a VM, package the code and deploy it to the VM. The workflows are re-usable between staging and production. They deploy to different environments in azure, keeping production and staging separate.

## first run bootstrapping
The deployment process requires an app registration (from which you derive a client id) and a service principal (with which you grant permissions to), so I have a bash script to configure both via the azure-cli, along with setting up a federated credential for GitHub's OIDC. The script will output the client id, tenant id and subscription ids upon completion, which will need to be saved into the repo's env vars for use by the runners. These three values are identifiers, not secrets.
