@description('Azure region for the VNet')
param location string

@description('Name of the virtual network')
param vnetName string = 'vnet-vpn'

@description('VNet address space')
param vnetAddressPrefix string = '10.100.0.0/16'

@description('Default subnet address prefix')
param subnetPrefix string = '10.100.1.0/24'

@description('Network security group resource ID to associate with subnet')
param nsgId string

resource vnet 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'snet-default'
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsgId
          }
        }
      }
    ]
  }
}

output vnetId string = vnet.id
output subnetId string = vnet.properties.subnets[0].id
