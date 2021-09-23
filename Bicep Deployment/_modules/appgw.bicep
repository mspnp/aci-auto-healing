param prefix string
param appgwSubnetId string
param appgwName string = '${prefix}-appgw'
param frontendIpConfiguration string = 'appgwPublicFrontendIp'
param frontendPort string = 'fe-port-80'
param backendPool string = 'bepool'
param backendHttpSetting string = 'behttp-port-80'
param httpListener string = 'listener-port-80'
param aciIPList array

resource pip 'Microsoft.Network/publicIPAddresses@2021-02-01' = {
  name: '${prefix}-pip'
  location: resourceGroup().location
  sku:{
    name: 'Standard'
    tier: 'Regional'
  }
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
    dnsSettings:{
      domainNameLabel: '${prefix}${uniqueString(resourceGroup().id)}'
    }
  }
}

resource appgw 'Microsoft.Network/applicationGateways@2021-02-01' = {
  name: appgwName
  location: resourceGroup().location
  zones:[
    '1'
    '2'
    '3'
  ]
  properties:{
    sku:{
      name: 'Standard_v2'
      tier: 'Standard_v2'
      capacity: 2
    }
    gatewayIPConfigurations:[
      {
        name: 'appgwGatewayIpConfig'
        properties:{
          subnet:{
            id: appgwSubnetId
          }
        }
      }
    ]
    frontendIPConfigurations:[
      {
        name: frontendIpConfiguration
        properties:{
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress:{
            id: pip.id
          }
        }
      }
    ]
    frontendPorts:[
      {
        name: frontendPort
        properties:{
          port: 80
        }
      }
    ]
    backendAddressPools:[
      {
        name: backendPool
        properties:{
          backendAddresses: aciIPList
        }
      }
    ]
    backendHttpSettingsCollection:[
      {
        name: backendHttpSetting
        properties:{
          port: 5000
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          pickHostNameFromBackendAddress: false
          requestTimeout: 20
        }
      }
    ]
    httpListeners:[
      {
        name: httpListener
        properties:{
          frontendIPConfiguration:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appgwName)}/frontendIPConfigurations/${frontendIpConfiguration}'
          }
          frontendPort:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appgwName)}/frontendPorts/${frontendPort}'
          }
          protocol:'Http'
        }
      }
    ]
    requestRoutingRules:[
      {
        name: 'rule1'
        properties:{
          ruleType: 'Basic'
          httpListener:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appgwName)}/httpListeners/${httpListener}'
          }
          backendAddressPool:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appgwName)}/backendAddressPools/${backendPool}'
          }
          backendHttpSettings:{
            id: '${resourceId('Microsoft.Network/applicationGateways', appgwName)}/backendHttpSettingsCollection/${backendHttpSetting}'
          }
        }
      }
    ]
  }
}

output backedPoolName string = backendPool
output backendHttpSetting string = backendHttpSetting
output httpListenerName string = httpListener
output appGWName string = appgwName
output appGWId string = appgw.id
output fqdnDomainName string = pip.properties.dnsSettings.fqdn
