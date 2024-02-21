param prefix string
param functionAppResourceId string
param functionName string
param functionHttpUrl string
param healthyThreshold int
param alertScope array
param rgLocation string = resourceGroup().location

resource actionGroup 'microsoft.insights/actionGroups@2023-01-01'={
  name: '${prefix}-aci-ag'
  location: 'Global'
  properties:{
    armRoleReceivers:[
      {
        name: 'email'
        roleId: '8e3af657-a8ff-443c-a75c-2fe8c4bcb635'
        useCommonAlertSchema: true
      }
    ]
    azureFunctionReceivers:[
      {
        name: 'function'
        functionAppResourceId: functionAppResourceId
        functionName: functionName
        httpTriggerUrl: functionHttpUrl
        useCommonAlertSchema: true
      }
    ]
    groupShortName: '${prefix}-aci-ag'
    enabled: true
  }
}

resource metricAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: '${prefix}-aci-alerts'
  location: 'Global'
  properties:{
    severity: 2
    enabled: true
    scopes: alertScope
    evaluationFrequency: 'PT1M'
    windowSize: 'PT1M'
    criteria:{
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf:[
        {
          threshold: healthyThreshold
          name: 'Metric1'
          metricNamespace: 'Microsoft.Network/applicationGateways'
          metricName: 'HealthyHostCount'
          operator: 'LessThanOrEqual'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Network/applicationGateways'
    targetResourceRegion: rgLocation
    actions: [
      {
        actionGroupId: actionGroup.id
      }
    ]
  }
}

