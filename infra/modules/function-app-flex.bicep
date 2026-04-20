@description('Location for the Function App resources.')
param location string

@description('Storage account used by Azure Functions runtime and deployment package storage.')
param functionStorageAccountName string

@description('Azure Functions Flex Consumption plan name.')
param functionPlanName string

@description('Azure Function App name.')
param functionAppName string

@description('Blob container used by Azure Functions Flex Consumption for deployment packages.')
param deploymentContainerName string

@description('Python runtime version for the Function App.')
param functionRuntimeVersion string

@description('Cosmos DB Table API table name used by the visitor counter.')
param tableName string

@description('Cosmos DB account name for the visitor counter.')
param cosmosAccountName string

@description('Tags applied to deployed resources.')
param tags object = {}

var functionStorageConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${functionStorage.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${functionStorage.listKeys().keys[0].value}'
var cosmosConnectionString = cosmosAccount.listConnectionStrings().connectionStrings[0].connectionString

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' existing = {
  name: cosmosAccountName
}

resource functionStorage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: functionStorageAccountName
  location: location
  tags: tags
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    accessTier: 'Hot'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    defaultToOAuthAuthentication: false
    minimumTlsVersion: 'TLS1_2'
    publicNetworkAccess: 'Enabled'
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: functionStorage
  name: 'default'
  properties: {
    deleteRetentionPolicy: {
      enabled: false
    }
    containerDeleteRetentionPolicy: {
      enabled: false
    }
  }
}

resource deploymentContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: deploymentContainerName
  properties: {
    publicAccess: 'None'
  }
}

resource functionPlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: functionPlanName
  location: location
  tags: tags
  kind: 'functionapp'
  sku: {
    name: 'FC1'
    tier: 'FlexConsumption'
  }
  properties: {
    reserved: true
  }
}

resource functionApp 'Microsoft.Web/sites@2024-04-01' = {
  name: functionAppName
  location: location
  tags: tags
  kind: 'functionapp,linux'
  properties: {
    serverFarmId: functionPlan.id
    httpsOnly: true
    clientAffinityEnabled: false
    functionAppConfig: {
      deployment: {
        storage: {
          type: 'blobContainer'
          value: '${functionStorage.properties.primaryEndpoints.blob}${deploymentContainerName}'
          authentication: {
            type: 'StorageAccountConnectionString'
            storageAccountConnectionStringName: 'DEPLOYMENT_STORAGE_CONNECTION_STRING'
          }
        }
      }
      runtime: {
        name: 'python'
        version: functionRuntimeVersion
      }
      scaleAndConcurrency: {
        instanceMemoryMB: 512
        maximumInstanceCount: 100
      }
    }
    siteConfig: {
      minTlsVersion: '1.2'
      cors: {
        allowedOrigins: [
          'https://portal.azure.com'
        ]
        supportCredentials: false
      }
    }
  }
  dependsOn: [
    deploymentContainer
  ]
}

resource appSettings 'Microsoft.Web/sites/config@2024-04-01' = {
  parent: functionApp
  name: 'appsettings'
  properties: {
    AzureWebJobsStorage: functionStorageConnectionString
    DEPLOYMENT_STORAGE_CONNECTION_STRING: functionStorageConnectionString
    STORAGE_CONNECTION_STRING: cosmosConnectionString
    TABLE_NAME: tableName
  }
}

output functionAppName string = functionApp.name
output defaultHostName string = functionApp.properties.defaultHostName
