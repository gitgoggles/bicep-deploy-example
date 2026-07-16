targetScope = 'resourceGroup'

param location string
param namePrefix string
param postgresAdminLogin string
@secure()
param postgresAdminPassword string
param tags object = {}

@description('App Service plan SKU. B1 is suitable for small non-production workloads.')
param appServicePlanSku string = 'B1'

@description('Linux runtime for the .NET API.')
param linuxFxVersion string = 'DOTNETCORE|8.0'

@description('PostgreSQL compute SKU.')
param postgresSkuName string = 'Standard_B1ms'

@description('PostgreSQL storage size in GiB.')
param postgresStorageSizeGB int = 32

@description('PostgreSQL major version.')
@allowed([
  '14'
  '15'
  '16'
  '17'
])
param postgresVersion string = '16'

var suffix = uniqueString(resourceGroup().id)
var staticWebAppName = '${namePrefix}-web-${suffix}'
var appServicePlanName = '${namePrefix}-plan-${suffix}'
var apiAppName = '${namePrefix}-api-${suffix}'
var postgresServerName = toLower('${namePrefix}-pg-${suffix}')
var postgresDatabaseName = 'appdb'

resource staticWebApp 'Microsoft.Web/staticSites@2025-03-01' = {
  name: staticWebAppName
  location: location
  tags: tags
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {
    allowConfigFileUpdates: true
    stagingEnvironmentPolicy: 'Enabled'
  }
}

resource appServicePlan 'Microsoft.Web/serverfarms@2025-03-01' = {
  name: appServicePlanName
  location: location
  tags: tags
  sku: {
    name: appServicePlanSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource postgresServer 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: postgresServerName
  location: location
  tags: tags
  sku: {
    name: postgresSkuName
    tier: 'Burstable'
  }
  properties: {
    administratorLogin: postgresAdminLogin
    administratorLoginPassword: postgresAdminPassword
    version: postgresVersion
    createMode: 'Create'
    storage: {
      storageSizeGB: postgresStorageSizeGB
      autoGrow: 'Enabled'
    }
    backup: {
      backupRetentionDays: 7
      geoRedundantBackup: 'Disabled'
    }
    highAvailability: {
      mode: 'Disabled'
    }
    network: {
      publicNetworkAccess: 'Enabled'
    }
    authConfig: {
      activeDirectoryAuth: 'Disabled'
      passwordAuth: 'Enabled'
    }
  }
}

resource allowAzureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgresServer
  name: 'AllowAzureServices'
  properties: {
    startIpAddress: '0.0.0.0'
    endIpAddress: '0.0.0.0'
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgresServer
  name: postgresDatabaseName
  properties: {
    charset: 'UTF8'
    collation: 'en_US.utf8'
  }
}

var postgresConnectionString = 'Host=${postgresServer.properties.fullyQualifiedDomainName};Port=5432;Database=${postgresDatabase.name};Username=${postgresAdminLogin};Password=${postgresAdminPassword};SSL Mode=Require;Trust Server Certificate=false'

resource apiApp 'Microsoft.Web/sites@2025-03-01' = {
  name: apiAppName
  location: location
  tags: tags
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    publicNetworkAccess: 'Enabled'
    siteConfig: {
      linuxFxVersion: linuxFxVersion
      alwaysOn: appServicePlanSku != 'F1'
      ftpsState: 'Disabled'
      minTlsVersion: '1.2'
      http20Enabled: true
      appSettings: [
        {
          name: 'ASPNETCORE_ENVIRONMENT'
          value: 'Production'
        }
        {
          name: 'WEBSITES_PORT'
          value: '8080'
        }
        {
          name: 'ConnectionStrings__DefaultConnection'
          value: postgresConnectionString
        }
      ]
      cors: {
        allowedOrigins: [
          'https://${staticWebApp.properties.defaultHostname}'
        ]
        supportCredentials: false
      }
    }
  }
  dependsOn: [
    allowAzureServices
    postgresDatabase
  ]
}

output staticWebAppName string = staticWebApp.name
output staticWebAppHostname string = staticWebApp.properties.defaultHostname
output apiAppName string = apiApp.name
output apiUrl string = 'https://${apiApp.properties.defaultHostName}'
output postgresServerName string = postgresServer.name
output postgresHostname string = postgresServer.properties.fullyQualifiedDomainName
output databaseName string = postgresDatabase.name
