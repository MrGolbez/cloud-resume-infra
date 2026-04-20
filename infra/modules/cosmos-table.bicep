@description('Location for the Cosmos DB account.')
param location string

@description('Cosmos DB account name.')
param cosmosAccountName string

@description('Cosmos DB Table API table name.')
param tableName string

@description('Tags applied to deployed resources.')
param tags object = {}

resource cosmosAccount 'Microsoft.DocumentDB/databaseAccounts@2024-05-15' = {
  name: cosmosAccountName
  location: location
  tags: tags
  kind: 'GlobalDocumentDB'
  properties: {
    databaseAccountOfferType: 'Standard'
    enableFreeTier: false
    publicNetworkAccess: 'Enabled'
    disableLocalAuth: false
    consistencyPolicy: {
      defaultConsistencyLevel: 'BoundedStaleness'
      maxIntervalInSeconds: 86400
      maxStalenessPrefix: 1000000
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
        isZoneRedundant: false
      }
    ]
    capabilities: [
      {
        name: 'EnableTable'
      }
      {
        name: 'EnableServerless'
      }
    ]
  }
}

resource counterTable 'Microsoft.DocumentDB/databaseAccounts/tables@2022-11-15' = {
  parent: cosmosAccount
  name: tableName
  tags: tags
  properties: {
    resource: {
      id: tableName
    }
    options: {}
  }
}

output cosmosAccountName string = cosmosAccount.name
output tableName string = counterTable.name
