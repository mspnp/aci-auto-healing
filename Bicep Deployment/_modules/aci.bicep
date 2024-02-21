param aciCount int
param rgLocation string = resourceGroup().location
param prefix string = 'gt'
param containerImage string
param acrServerName string
param acrLoginName string
param appInsightsKey string
param networkProfileId string

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrLoginName
}

var acrPassword = acr.listCredentials().passwords[0].value

resource aciList 'Microsoft.ContainerInstance/containerGroups@2021-03-01' = [for i in range(0,aciCount):{
  name: '${prefix}aci-${i}'
  location: rgLocation
  properties: {
    sku: 'Standard'
    imageRegistryCredentials:[
      {
        server: acrServerName
        username: acrLoginName
        password: acrPassword
      }
    ]
    containers: [
      {
        name: 'container-${i}'
        properties: {
          image: containerImage
          ports: [
            {
              protocol: 'TCP'
              port: 5000
            }
          ]
          environmentVariables: [
            {
              name: 'APP_INSIGHT_KEY'
              value: appInsightsKey
            }
          ]
          resources: {
            requests: {
              memoryInGB: 1
              cpu: 1
            }
          }
        }
      }
    ]
    restartPolicy: 'Always'
    osType: 'Linux'
    ipAddress:{
      type: 'Private'
      ports:[
        {
          protocol: 'TCP'
          port: 5000
        }
      ]
    }
    networkProfile:{
      id: networkProfileId
    }
  }
}]

output aciAddress array = [for i in range(0,aciCount):{
  ipAddress: aciList[i].properties.ipAddress.ip
}]
