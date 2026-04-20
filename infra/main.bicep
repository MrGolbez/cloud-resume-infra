targetScope = 'resourceGroup'

@description('Environment label used for tags and outputs.')
param environmentName string = 'prod'

@description('Location for the public static website storage account.')
param frontendLocation string = 'westus2'

@description('Location for backend compute resources.')
param backendLocation string = 'westus'

@description('Location for Cosmos DB Table API.')
param cosmosLocation string = 'westus2'

@description('Public static website storage account name.')
param staticSiteStorageAccountName string = 'martycraneresume26'

@description('Storage account name used by the Function App runtime and deployment package.')
param functionStorageAccountName string = 'rgcloudresumeproda986'

@description('Azure Functions Flex Consumption plan name.')
param functionPlanName string = 'ASP-rgcloudresumeprod-a8d4'

@description('Azure Function App name.')
param functionAppName string = 'martycrane-resume-api'

@description('Cosmos DB account name for the visitor counter.')
param cosmosAccountName string = 'martycrane-resume-db'

@description('Cosmos DB Table API table name used by the visitor counter.')
param tableName string = 'Counter'

@description('Blob container used by Azure Functions Flex Consumption for deployment packages.')
param deploymentContainerName string = 'app-package-martycrane-resume-api-1a81096'

@description('Python runtime version for the Function App.')
param functionRuntimeVersion string = '3.13'

var tags = {
  project: 'cloud-resume-challenge'
  environment: environmentName
  managedBy: 'bicep'
}

module staticSite './modules/static-site-storage.bicep' = {
  name: 'static-site-storage'
  params: {
    location: frontendLocation
    storageAccountName: staticSiteStorageAccountName
    tags: tags
  }
}

module cosmos './modules/cosmos-table.bicep' = {
  name: 'cosmos-table-api'
  params: {
    location: cosmosLocation
    cosmosAccountName: cosmosAccountName
    tableName: tableName
    tags: tags
  }
}

module functionApp './modules/function-app-flex.bicep' = {
  name: 'function-app-flex'
  params: {
    location: backendLocation
    functionStorageAccountName: functionStorageAccountName
    functionPlanName: functionPlanName
    functionAppName: functionAppName
    deploymentContainerName: deploymentContainerName
    functionRuntimeVersion: functionRuntimeVersion
    tableName: tableName
    cosmosAccountName: cosmosAccountName
    tags: tags
  }
  dependsOn: [
    cosmos
  ]
}

output staticWebsiteUrl string = staticSite.outputs.staticWebsiteUrl
output functionDefaultHostName string = functionApp.outputs.defaultHostName
output cosmosTableName string = cosmos.outputs.tableName
