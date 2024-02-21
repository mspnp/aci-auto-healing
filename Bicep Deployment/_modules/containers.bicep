param imageName string = 'hello-world:latest'
param location string =  resourceGroup().location

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' = {
  name: uniqueString(resourceGroup().id)
  location: location
  sku:{
    name: 'Basic'
  }
  properties:{
    adminUserEnabled: true
  }
}

resource acrBuildImage 'Microsoft.ContainerRegistry/registries/taskRuns@2019-06-01-preview' = {
  parent: acr
  name: 'hellotask'
  location: location
  properties: {
    runRequest: {
      type: 'DockerBuildRequest'
      dockerFilePath: 'Dockerfile'
      imageNames: [
        imageName
      ]
      sourceLocation: 'https://github.com/guangying94/aci-auto-healing.git'
      isPushEnabled: true
      platform: {
        os: 'Linux'
        architecture: 'amd64'
      }
    }
  }
}

output acrServerName string = acr.properties.loginServer
output acrLoginName string = acr.name
output container_image string = '${acr.properties.loginServer}/${imageName}'
