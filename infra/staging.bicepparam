using './main.bicep'

param resourceGroupName = 'rg-${workloadName}-${environmentName}'
param location = 'westcentralus'
param workloadName = 'bicep-deploy-example'
param environmentName = 'staging'
param appServicePlanSku = 'F1'
