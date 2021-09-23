//param peSubnetId string
param privateLinkSubnetId string
param vnetId string
param cosmosId string

resource cosmosPE 'Microsoft.Network/privateEndpoints@2021-02-01' = {
  name: '${uniqueString(resourceGroup().id)}-pe'
  location: resourceGroup().location
  properties:{
    privateLinkServiceConnections:[
      {
        name: '${uniqueString(resourceGroup().id)}_pe'
        properties:{
          privateLinkServiceId: cosmosId
          groupIds:[
            'Sql'
          ]
        }
      }
    ]
    subnet:{
      id: privateLinkSubnetId
    }
  }
}

resource privateDNSZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.documents.azure.com'
  location: 'Global'
}

resource privateDNSZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  name: '${privateDNSZone.name}/${privateDNSZone.name}-link'
  location: 'Global'
  properties:{
    registrationEnabled: false
    virtualNetwork:{
      id: vnetId
    }
  }
}

resource privateDNSZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-02-01' = {
  name: '${cosmosPE.name}/cosmosgroup'
  properties:{
    privateDnsZoneConfigs:[
      {
        name: 'config1'
        properties:{
          privateDnsZoneId: privateDNSZone.id
        }
      }
    ]
  }
}
