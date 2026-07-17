using './main.bicep'

param resourceGroupName = 'rg-bicep-deploy-example-prod-uks'
param location = 'westcentralus'
param workloadName = 'bicep-deploy-example'
param environmentName = 'prod'
param appServicePlanSku = 'F1'
