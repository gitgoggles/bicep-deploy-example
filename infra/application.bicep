targetScope = 'resourceGroup'

param location string
param workloadName string
param environmentName string
param appServicePlanSku string
param tags object = {}

var suffix = uniqueString(subscription().subscriptionId, workloadName, environmentName)
var appServicePlanName = 'asp-${workloadName}-${environmentName}'
var webAppName = 'app-${workloadName}-${environmentName}-${suffix}'
var supportsAlwaysOn = !contains([
  'F1'
  'D1'
], toUpper(appServicePlanSku))

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  kind: 'linux'
  sku: {
    name: appServicePlanSku
  }
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: webAppName
  location: location
  tags: tags
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    clientAffinityEnabled: false
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      alwaysOn: supportsAlwaysOn
      ftpsState: 'Disabled'
      http20Enabled: true
      linuxFxVersion: 'DOTNETCORE|10.0'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
      ]
    }
  }
}

output appServicePlanName string = appServicePlan.name
output webAppName string = webApp.name
output webAppUrl string = 'https://${webApp.properties.defaultHostName}'
