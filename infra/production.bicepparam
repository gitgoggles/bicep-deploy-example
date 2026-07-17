using './main.bicep'

param resourceGroupName = 'rg-${workloadName}-${environmentName}'
param location = 'westcentralus'
param workloadName = 'bicep-deploy-example'
param environmentName = 'production'
param appServicePlanSku = 'F1'
