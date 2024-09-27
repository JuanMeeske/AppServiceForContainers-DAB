param appName string = ''
param location string = ''
param containerImage string = 'mcr.microsoft.com/azure-databases/data-api-builder:latest'
@secure()
param adminPassword string = ''
param storageAccountName string = '' 
param publicIP string = ''

var appServicePlanName = '${appName}-plan'
var vnetName = '${appName}-vnet'
var subnetName = 'default'
var subnetId = resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)

//
// App Service Plan
//
resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: appServicePlanName
  location: location
  sku: {
    name: 'S1'  
    tier: 'Standard'  
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

//
// Virtual Network
//
resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '10.0.0.0/24'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
            }
            {
              service: 'Microsoft.Sql'
            }
            {
              service: 'Microsoft.Web'
            }
          ]
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
    ]
  }
}

//
// Storage Account
//
resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    
    networkAcls: {
      defaultAction: 'Deny'
      ipRules: [
        {
          value: publicIP
          action: 'Allow'
        }
      ]
      virtualNetworkRules: [
        {
          id: subnetId  
          action: 'Allow'
        }
      ]
    }
  }
  dependsOn: [
    vnet 
  ]
}

//
// Blob Service and Container
//
resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2021-08-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  parent: blobService
  name: 'default'
  properties: {
    publicAccess: 'None'
  }
  dependsOn: [
    storageAccount
  ]
}

//
// Web App
//
resource webApp 'Microsoft.Web/sites@2021-03-01' = {
  name: appName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    virtualNetworkSubnetId: subnetId
    siteConfig: {
      appSettings: [
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://index.docker.io'
        }
        {
          name: 'SQL_CONN_STRING'
          value: 'Server=tcp:sqlserver-${appName}.database.windows.net,1433;User Id=sqladmin;Database=db-${appName};Password=${adminPassword};Trusted_Connection=False;Encrypt=Optional;'
        }
        {
          name: 'ConfigFileName'
          value: '/App/configs/dab-config.json'
        }
        {
          name: 'WEBSITES_PORT'
          value: '5000'
        }
      ]
      linuxFxVersion: 'DOCKER|${containerImage}'
      logsDirectorySizeLimit: 35
      detailedErrorLoggingEnabled: true
      httpLoggingEnabled: true
      requestTracingEnabled: true
      ftpsState: 'FtpsOnly'
    }
  }
  dependsOn: [
    sqlServer
    storageAccount
    appServicePlan
    vnet
  ]
}
resource webAppConfig 'Microsoft.Web/sites/config@2021-03-01' = {
  parent: webApp
  name: 'azurestorageaccounts'
  properties: {
    config: {
      accountName: storageAccount.name
      shareName: blobContainer.name
      accessKey: storageAccount.listKeys().keys[0].value
      mountPath: '/App/configs'
      type: 'AzureBlob'
    }
  }
}



//
// SQL Server Module
//
module sqlServer 'br/public:avm/res/sql/server:0.6.0' = {
  name: 'sql-${appName}'
  params: {
    name: 'sqlserver-${appName}'
    administratorLogin: 'sqladmin'
    administratorLoginPassword: adminPassword
    location: location
    restrictOutboundNetworkAccess: 'Disabled'
    firewallRules: [
      {
        name: 'AllowPublicIP'
        startIpAddress: publicIP
        endIpAddress: publicIP
      }
    ]
    virtualNetworkRules: [
      {
        name: 'sql-${appName}'
        virtualNetworkSubnetId: subnetId
        ignoreMissingVnetServiceEndpoint: false
      }
    ]
    databases: [
      {
        name: 'db-${appName}'
        skuName: 'S0'
        skuTier: 'Standard'
        maxSizeBytes: 268435456000
        zoneRedundant: false
      }
    ]
  }
}
