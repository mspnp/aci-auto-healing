param deploy_prefix string
param rg_name string
param rg_location string
param aci_count int
param service_principal_id string
param service_principal_secret string

targetScope = 'subscription'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name:'${deploy_prefix}-${rg_name}-RG'
  location: rg_location
}

module vnet '_modules/vnet.bicep' = {
  name: 'vnet'
  scope: rg
  params:{
    prefix: deploy_prefix
  }
}

module monitoring '_modules/monitor.bicep' = {
  name: 'azuremonitor'
  scope: rg
  params:{
    prefix:deploy_prefix
  }
}

module acr '_modules/containers.bicep' = {
  name: 'azurecontainerregistry'
  scope: rg
}

module aci '_modules/aci.bicep' = {
  name: 'aci'
  scope: rg
  params:{
    prefix: deploy_prefix
    appInsightsKey: monitoring.outputs.appinsightKey
    networkProfileId: vnet.outputs.aciNetworkProfile
    aciCount: aci_count
    acrServerName: acr.outputs.acrServerName
    acrLoginName: acr.outputs.acrLoginName
    acrPassword: acr.outputs.acrPassword
    containerImage: acr.outputs.container_image
  }
}

module appgw '_modules/appgw.bicep' = {
  name: 'applicationGateway'
  scope: rg
  params:{
    prefix: deploy_prefix
    appgwSubnetId: vnet.outputs.appgwSubnet
    aciIPList: aci.outputs.aciAddress
  }
}

module functions '_modules/functions.bicep' = {
  name: 'azurefunction'
  scope: rg
  params:{
    prefix: deploy_prefix
    sp_client_id: service_principal_id
    sp_client_secret: service_principal_secret
    appGWName: appgw.outputs.appGWName
    appInsightInstrumentationKey: monitoring.outputs.instrumentationKey
    acrServerName: acr.outputs.acrServerName
    acrLoginName: acr.outputs.acrLoginName
    acrPassword: acr.outputs.acrPassword
    networkProfileName: vnet.outputs.aciNetworkProfileName
    appgw_bepool_name: appgw.outputs.backedPoolName
    appgw_listener_name: appgw.outputs.httpListenerName
    appgw_httpsetting_name: appgw.outputs.backendHttpSetting
  }
}

module cosmos '_modules/cosmosdb.bicep'= {
  name: 'azurecosmosdb'
  scope: rg
}

module privatelink '_modules/privatelink.bicep'={
  name: 'privatelink'
  scope: rg
  params:{
    privateLinkSubnetId: vnet.outputs.privatelinkSubnet
    vnetId: vnet.outputs.vnetId
    cosmosId: cosmos.outputs.cosmosId
  }
}

module alerts '_modules/alerts.bicep'={
  name:'azuremonitoralert'
  scope: rg
  params:{
    prefix: deploy_prefix
    functionAppResourceId: functions.outputs.functionId
    functionName: 'aci_healing_durable_HttpStart'
    functionHttpUrl: 'https://${functions.outputs.functionUrl}/api/aci_healing_durable_HttpStart'
    healthyThreshold: aci_count - 1
    alertScope: array(appgw.outputs.appGWId)
  }
}
