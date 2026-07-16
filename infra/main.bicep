targetScope = 'subscription'

@description('Name of the resource group to create.')
param resourceGroupName string

@description('Azure region for the resource group and regional resources.')
param location string = deployment().location

@description('Short, globally unique prefix used in resource names. Use lowercase letters and numbers only.')
@minLength(3)
@maxLength(12)
param namePrefix string

@description('PostgreSQL administrator login name.')
param postgresAdminLogin string

@secure()
@description('PostgreSQL administrator password.')
param postgresAdminPassword string

@description('Environment tag, for example dev, test, or prod.')
param environmentName string = 'dev'

var tags = {
  environment: environmentName
  workload: 'react-dotnet-postgresql'
  managedBy: 'bicep'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module application './application.bicep' = {
  name: 'application-${uniqueString(resourceGroup.id)}'
  scope: resourceGroup
  params: {
    location: location
    namePrefix: namePrefix
    postgresAdminLogin: postgresAdminLogin
    postgresAdminPassword: postgresAdminPassword
    tags: tags
  }
}

output resourceGroupName string = resourceGroup.name
output staticWebAppHostname string = application.outputs.staticWebAppHostname
output apiUrl string = application.outputs.apiUrl
output postgresHostname string = application.outputs.postgresHostname
output databaseName string = application.outputs.databaseName
