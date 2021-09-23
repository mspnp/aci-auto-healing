param imageName string = 'hello-world:latest'

resource acr 'Microsoft.ContainerRegistry/registries@2021-06-01-preview' = {
  name: uniqueString(resourceGroup().id)
  location: resourceGroup().location
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
  location: resourceGroup().location
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

output acrPassword string = acr.listCredentials().passwords[0].value
output acrServerName string = acr.properties.loginServer
output acrLoginName string = acr.name
output container_image string = '${acr.properties.loginServer}/${imageName}'
