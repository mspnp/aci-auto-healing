param prefix string = 'gt'
param rgLocation string = resourceGroup().location

resource laworkspace 'microsoft.operationalinsights/workspaces@2022-10-01' = {
  name: '${prefix}-app-workspace'
  location: rgLocation
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    features: {
      enableLogAccessUsingOnlyResourcePermissions: true
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

resource appinsight 'microsoft.insights/components@2020-02-02' = {
  name: uniqueString(resourceGroup().id)
  location: rgLocation
  kind: 'web'
  properties: {
    Application_Type: 'web'
    RetentionInDays: 90
    WorkspaceResourceId: laworkspace.id
    IngestionMode: 'LogAnalytics'
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

output appinsightKey string = appinsight.properties.ConnectionString
output instrumentationKey string = appinsight.properties.InstrumentationKey
