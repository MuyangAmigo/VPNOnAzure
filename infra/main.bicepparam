using './main.bicep'

// These values are overridden by deploy.sh from .env — edit .env instead
param location = 'southeastasia'
param vmSize = 'Standard_B2s'

// Injected by deploy.sh at deploy time — do not edit manually
param sshPublicKey = '<INJECTED_BY_DEPLOY_SCRIPT>'
param cloudInitData = '<INJECTED_BY_DEPLOY_SCRIPT>'

// Restrict SSH access to a specific IP (optional, default allows any)
// param allowSshFrom = '1.2.3.4'

// Optional: DNS label gives you <label>.<region>.cloudapp.azure.com
// param dnsLabel = 'myvpn'
