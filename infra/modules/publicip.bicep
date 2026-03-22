@description('Azure region')
param location string

@description('Name of the public IP resource')
param publicIpName string = 'pip-wireguard'

@description('Optional DNS label for stable hostname')
param dnsLabel string = ''

resource publicIp 'Microsoft.Network/publicIPAddresses@2023-11-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: empty(dnsLabel) ? null : {
      domainNameLabel: dnsLabel
    }
  }
}

output publicIpId string = publicIp.id
output publicIpAddress string = publicIp.properties.ipAddress
