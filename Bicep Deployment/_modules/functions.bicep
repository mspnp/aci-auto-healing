param prefix string
param sp_client_id string
@secure()
param sp_client_secret string
param appGWName string
param appInsightInstrumentationKey string
param acrServerName string
param acrLoginName string
param networkProfileName string
param appgw_bepool_name string
param appgw_listener_name string
param appgw_httpsetting_name string
param location string =  resourceGroup().location

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' existing = {
  name: acrLoginName
}

var acrPassword = acr.listCredentials().passwords[0].value

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-01-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  kind: 'StorageV2'
  sku: {
    name: 'Standard_LRS'
  }
}


resource functionPlan 'Microsoft.Web/serverfarms@2022-09-01' = {
  name: 'functionPlan'
  location: location
  sku:{
    name: 'Y1'
    tier: 'Dynamic'
  }
}

resource functionApp 'Microsoft.Web/sites@2022-09-01' = {
  name: '${prefix}-${uniqueString(resourceGroup().id)}'
  location: location
  kind: 'functionapp'
  properties:{
    httpsOnly: true
    serverFarmId: functionPlan.id
    clientAffinityEnabled: true
    siteConfig:{
      appSettings:[
        {
          name: 'SP_CLIENT_ID'
          value: sp_client_id
        }
        {
          name: 'SP_CLIENT_SECRET'
          value: sp_client_secret
        }
        {
          name: 'TENANT_ID'
          value: subscription().tenantId
        }
        {
          name: 'SUBS_ID'
          value: subscription().subscriptionId
        }
        {
          name: 'RG_NAME'
          value: resourceGroup().name
        }
        {
          name: 'APPGW_NAME'
          value: appGWName
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightInstrumentationKey
        }
        {
          name: 'ACR_SERVER_NAME'
          value: acrServerName
        }
        {
          name: 'ACR_USERNAME'
          value: acrLoginName
        }
        {
          name: 'ACR_PW'
          value: acrPassword
        }
        {
          name: 'NETWORK_PROFILE_NAME'
          value: networkProfileName
        }
        {
          name: 'APPGW_BEPOOL_NAME'
          value: appgw_bepool_name
        }
        {
          name: 'APPGW_LISTENER_NAME'
          value: appgw_listener_name
        }
        {
          name: 'APPGW_HTTPSETTING_NAME'
          value: appgw_httpsetting_name
        }
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
        }
        {
          name: 'WEBSITE_RUN_FROM_PACKAGE'
          value: 'https://guteemsftshared.blob.${environment().suffixes.storage}/external/Compiled-Functions-Code.zip'
        }
      ]
    }
  }
}

output functionAppName string = functionApp.name
output functionId string = functionApp.id
output functionUrl string = functionApp.properties.defaultHostName
