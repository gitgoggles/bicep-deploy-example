targetScope = 'subscription'

@description('Name of the resource group to create or update.')
param resourceGroupName string

@description('Azure region for the resource group and App Service resources.')
param location string = deployment().location

@description('Short workload name used in resource names.')
param workloadName string = 'bicep-deploy-example'

@allowed([
  'dev'
  'test'
  'prod'
])
@description('Deployment environment name.')
param environmentName string

@description('App Service Plan SKU. F1 is intended only for demonstration and low-traffic use.')
param appServicePlanSku string = 'F1'

var tags = {
  environment: environmentName
  workload: workloadName
  managedBy: 'bicep'
}

resource resourceGroup 'Microsoft.Resources/resourceGroups@2025-04-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

module application './application.bicep' = {
  name: 'application-${environmentName}'
  scope: resourceGroup
  params: {
    appServicePlanSku: appServicePlanSku
    environmentName: environmentName
    location: location
    tags: tags
    workloadName: workloadName
  }
}

output resourceGroupName string = resourceGroup.name
output appServicePlanName string = application.outputs.appServicePlanName
output webAppName string = application.outputs.webAppName
output webAppUrl string = application.outputs.webAppUrl
