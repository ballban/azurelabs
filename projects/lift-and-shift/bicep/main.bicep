targetScope = 'subscription'

param location string = 'eastasia'
param resourceGroupName string = 'jung-lift-and-shift'
@secure()
param password string

resource resourceGroup 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
}

module regource 'resourcesModule.bicep' = {
  scope: resourceGroup
  name: 'CreateVM'
  params: {
    location: location
    adminPassword: password
  }
}
