targetScope = 'resourceGroup'

param location string
@secure()
param adminPassword string

param vnetName string = 'jung-app-vnet'
param subnetName string = 'jung-app-subnet'
param nsgName string = 'jung-app-nsg'

param vmName string = uniqueString('vm', resourceGroup().id)
param dnsLabelPrefix string = toLower('lift-and-shift-${vmName}')
param vmSize string = 'Standard_D2s_v4'
param adminUsername string = 'labs'

var publicIPAddressName = '${vmName}-pip'
var networkInterfaceName = '${vmName}-nic'
var osDiskType = 'Standard_LRS'
var windowsServerSku = '2022-datacenter-g2'
var privateIpAddress = '10.1.0.103'

var subnetAddressPrefix = '10.1.0.0/24'
var addressPrefix = '10.1.0.0/16'

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'HTTP'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '80'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
  }
}

resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-08-01' = {
  parent: virtualNetwork
  name: subnetName
  properties: {
    addressPrefix: subnetAddressPrefix
    privateEndpointNetworkPolicies: 'Enabled'
    privateLinkServiceNetworkPolicies: 'Enabled'
    serviceEndpoints: [
      {
        locations: [
          '*'
        ]
        service: 'Microsoft.Sql'
      }
    ]
  }
}

resource networkInterface 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: networkInterfaceName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnet.id
          }
          privateIPAllocationMethod: 'Static'
          privateIPAddressVersion: 'IPv4'
          privateIPAddress: privateIpAddress
          publicIPAddress: {
            id: publicIPAddress.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: networkSecurityGroup.id
    }
  }
}

resource publicIPAddress 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Basic'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
    publicIPAddressVersion: 'IPv4'
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
    idleTimeoutInMinutes: 4
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    storageProfile: {
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: osDiskType
        }
      }
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: windowsServerSku
        version: 'latest'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: networkInterface.id
        }
      ]
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
  }
}

resource vmRunCommand 'Microsoft.Compute/virtualMachines/runCommands@2022-03-01' = {
  name: 'vmSetup'
  location: location
  parent: vm
  properties: {
    asyncExecution: false
    source: {
      scriptUri: 'https://jungfile.blob.core.windows.net/file/setup.ps1'
    }
    timeoutInSeconds: 600
  }
}

output url string = 'http://${publicIPAddress.properties.dnsSettings.fqdn}/signup'
