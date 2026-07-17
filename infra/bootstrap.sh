#!/usr/bin/env bash
set -euo pipefail

# azure cli and github cli need to be logged in.
# the script will fail early if you are not.
az account show
gh auth status

APP_NAME="bicep-deploy-example"
GITHUB_OWNER="gitgoggles"
GITHUB_REPO="bicep-deploy-example"
ENVIRONMENT='production'

SUBSCRIPTION_ID="$(az account show --query id --output tsv)"
GITHUB_OWNER_ID="$(gh api "repos/${GITHUB_ORG}/${GITHUB_REPO}" --jq '.owner.id')"
GITHUB_REPO_ID="$(gh api "repos/${GITHUB_ORG}/${GITHUB_REPO}" --jq '.id')"

APP_ID="$(az ad app create --display-name "$APP_NAME" --query appId --output tsv)"

az ad sp create --id "$APP_ID"

SP_OBJECT_ID="$(az ad sp show --id "$APP_ID" --query id --output tsv)"

az role assignment create --assignee-object-id "$SP_OBJECT_ID" --assignee-principal-type ServicePrincipal --role Contributor --scope "/subscriptions/$SUBSCRIPTION_ID"

cat > federated-credential.json <<EOF
{
  "name": "github-${ENVIRONMENT}",
  "issuer": "https://token.actions.githubusercontent.com",
  "subject": "repo:${GITHUB_OWNER}@${GITHUB_OWNER_ID}/${GITHUB_REPO}@${GITHUB_REPO_ID}:environment:${ENVIRONMENT}",
  "description": "Deployments from the ${ENVIRONMENT} environment",
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

gh variable set AZURE_CLIENT_ID --body "${APP_ID}" --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --env "${ENVIRONMENT}"
gh variable set AZURE_TENANT_ID --body "${TENANT_ID}" --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --env "${ENVIRONMENT}"
gh variable set AZURE_SUBSCRIPTION_ID --body "${SUBSCRIPTION_ID}" --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --env "${ENVIRONMENT}"
gh variable list --repo "${GITHUB_OWNER}/${GITHUB_REPO}" --env "${ENVIRONMENT}"
