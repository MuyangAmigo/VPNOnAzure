targetScope = 'resourceGroup'

@description('Azure region for all resources')
param location string = 'eastus'

@description('VM size for WireGuard server')
param vmSize string = 'Standard_B1s'

@description('SSH public key for VM authentication')
param sshPublicKey string

@description('Base64-encoded cloud-init data for WireGuard setup')
param cloudInitData string

@description('Source IP range allowed for SSH access (default: any)')
param allowSshFrom string = '*'

@description('Optional DNS label for stable public hostname')
param dnsLabel string = ''

// Network Security Group
module nsg 'modules/nsg.bicep' = {
  name: 'deploy-nsg'
  params: {
    location: location
    allowSshFrom: allowSshFrom
  }
}

// Virtual Network
module vnet 'modules/vnet.bicep' = {
  name: 'deploy-vnet'
  params: {
    location: location
    nsgId: nsg.outputs.nsgId
  }
}

// Public IP for WireGuard VM
module publicIp 'modules/publicip.bicep' = {
  name: 'deploy-publicip'
  params: {
    location: location
    dnsLabel: dnsLabel
  }
}

// WireGuard VM
module vm 'modules/vm.bicep' = {
  name: 'deploy-vm'
  params: {
    location: location
    vmSize: vmSize
    subnetId: vnet.outputs.subnetId
    publicIpId: publicIp.outputs.publicIpId
    sshPublicKey: sshPublicKey
    cloudInitData: cloudInitData
  }
}

output publicIpAddress string = publicIp.outputs.publicIpAddress
output vmName string = vm.outputs.vmName
