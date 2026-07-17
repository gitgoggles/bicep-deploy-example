#!/usr/bin/env bash
set -euo pipefail

APP_NAME="bicep-deploy-example"
GITHUB_OWNER="gitgoggles"
GITHUB_REPO="bicep-deploy-example"
SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
GITHUB_OWNER_ID="$(gh api "repos/${GITHUB_ORG}/${GITHUB_REPO}" --jq '.owner.id')"
GITHUB_REPO_ID="$(gh api "repos/${GITHUB_ORG}/${GITHUB_REPO}" --jq '.id')"

APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)"

az ad sp create --id "$APP_ID"

OBJECT_ID="$(az ad sp show --id "$APP_ID" --query id --output tsv)"

az role assignment create --assignee-object-id "$OBJECT_ID" --assignee-principal-type ServicePrincipal --role Contributor --scope "/subscriptions/$SUBSCRIPTION_ID"

cat > federated-credential.json <<EOF
{
  "name": "github-production",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_OWNER}@${GITHUB_OWNER_ID}/${GITHUB_REPO}@${GITHUB_REPO_ID}:environment:production",
  "description": "Deployments from the production environment",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az ad app federated-credential create --id "$APP_ID" --parameters federated-credential.json

TENANT_ID="$(az account show --query tenantId --output tsv)"

printf 'AZURE_CLIENT_ID=%s\n' "$APP_ID"
printf 'AZURE_TENANT_ID=%s\n' "$TENANT_ID"
printf 'AZURE_SUBSCRIPTION_ID=%s\n' "$SUBSCRIPTION_ID"
