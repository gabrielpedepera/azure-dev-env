targetScope = 'subscription'

param rgName string = 'rg-remote-development'
param location string = 'northeurope'

@secure()
param sshPublicKey string

// 1. Create the Resource Group container
resource devRG 'Microsoft.Resources/resourceGroups@2023-07-01' = {
  name: rgName
  location: location
}

// 2. Deploy the VM into that Resource Group
module workstation './dev-workstation.bicep' = {
  name: 'workstation-deployment'
  scope: devRG
  params: {
    location: location
    sshPublicKey: sshPublicKey
    vmName: 'ubuntu-remote-dev'
    adminUsername: 'gabrielpedepera'
  }
}
