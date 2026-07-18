targetScope = 'subscription'

param workloadName string = 'bicep-deploy-example'
param resourceGroupName string = 'rg-${workloadName}-${environmentName}'
param location string

@allowed([
  'production'
  'staging'
])
param environmentName string
param appServicePlanSku string

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
