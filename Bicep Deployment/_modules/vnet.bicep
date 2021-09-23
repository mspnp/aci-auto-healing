param prefix string

resource vnet 'Microsoft.Network/virtualNetworks@2021-02-01' = {
  name: '${prefix}-vnet'
  location: resourceGroup().location
  properties:{
    addressSpace:{
      addressPrefixes: [
        '10.10.0.0/24'
      ]
    }
  }
}

resource appgwSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'appgw-subnet'
  properties: {
    addressPrefix: '10.10.0.0/26'
  }
}

resource aciSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent: vnet
  name: 'aci-subnet'
  properties: {
    addressPrefix: '10.10.0.64/27'
    delegations:[
      {
        name: 'Microsoft.ContainerInstance/containerGroups'
        properties:{
          serviceName: 'Microsoft.ContainerInstance/containerGroups'
        }
      }
    ]
  }
}

resource privatelinkSubnet 'Microsoft.Network/virtualNetworks/subnets@2020-11-01' = {
  parent:vnet
  name: 'privatelink-subnet'
  properties: {
    addressPrefix: '10.10.0.96/27'
    privateEndpointNetworkPolicies: 'Disabled'
  }
}

resource aciNetworkProfile 'Microsoft.Network/networkProfiles@2021-02-01' = {
  name: '${aciSubnet.name}-network-profile'
  location: resourceGroup().location
  properties:{
    containerNetworkInterfaceConfigurations:[
      {
        name: 'eth0'
        properties:{
          ipConfigurations:[
            {
              name: 'ipconfigprofile'
              properties:{
                subnet:{
                  id: aciSubnet.id
                }
              }
            }
          ]
        }
      }
    ]
  }
}

output aciNetworkProfile string = aciNetworkProfile.id
output aciNetworkProfileName string = '${aciSubnet.name}-network-profile'
output aciSubnet string = aciSubnet.id
output appgwSubnet string = appgwSubnet.id
output privatelinkSubnet string = privatelinkSubnet.id
output vnetName string = '${prefix}-vnet'
output vnetId string = vnet.id
