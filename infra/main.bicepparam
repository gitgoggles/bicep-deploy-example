using './main.bicep'

param resourceGroupName = 'rg-myapp-dev-uks'
param location = 'uksouth'
param namePrefix = 'myapp'
param environmentName = 'dev'
param postgresAdminLogin = 'pgadminuser'
// Supply the secure password at deployment time instead of storing it here.
