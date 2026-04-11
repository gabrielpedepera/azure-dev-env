param location string
param vmName string
param adminUsername string
@secure()
param sshPublicKey string

resource nsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowSSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: '*' // We can restrict this to your IP later
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

// Network Resources
resource vnet 'Microsoft.Network/virtualNetworks@2023-09-01' = {
  name: '${vmName}-vnet'
  location: location
  properties: {
    addressSpace: { addressPrefixes: ['10.0.0.0/16'] }
    subnets: [{ name: 'default', properties: { addressPrefix: '10.0.1.0/24' } }]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2023-09-01' = {
  name: '${vmName}-ip'
  location: location
  sku: { name: 'Standard' }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: 'ubuntu-dev-workstation'
    }
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2023-09-01' = {
  name: '${vmName}-nic'
  location: location
  properties: {
    // 2. LINKED: The NSG must be attached to the NIC
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: { id: vnet.properties.subnets[0].id }
          publicIPAddress: { id: pip.id }
        }
      }
    ]
  }
}

// Virtual Machine Resource
resource vm 'Microsoft.Compute/virtualMachines@2024-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: { vmSize: 'Standard_D2s_v5' }
    securityProfile: {
      securityType: 'TrustedLaunch'
      uefiSettings: { secureBootEnabled: true, vTpmEnabled: true }
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: 'ubuntu-24_04-lts'
        sku: 'ubuntu-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: { storageAccountType: 'Premium_LRS' }
        deleteOption: 'Delete'
      }
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      linuxConfiguration: {
        disablePasswordAuthentication: true
        ssh: {
          publicKeys: [
            {
              path: '/home/${adminUsername}/.ssh/authorized_keys'
              keyData: sshPublicKey
            }
          ]
        }
      }
      customData: base64('''
#cloud-config
package_update: true
packages: [git, curl, zsh, unzip, xz-utils, fontconfig, build-essential, python3-pip, docker.io]
runcmd:
  - systemctl enable docker
  - usermod -aG docker gabrielpedepera
  - fallocate -l 2G /swapfile && chmod 600 /swapfile && mkswap /swapfile && swapon /swapfile
  - echo '/swapfile none swap sw 0 0' >> /etc/fstab
  - curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && apt-get install -y nodejs
  - chsh -s /usr/bin/zsh gabrielpedepera
  # Install chezmoi and apply dotfiles as the user
  - su - gabrielpedepera -c 'sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"'
  - su - gabrielpedepera -c 'mkdir -p "$HOME/.config/chezmoi" && printf "[data]\n    name = \"Gabriel Pereira\"\n    email = \"gabrielpedepera@gmail.com\"\n" > "$HOME/.config/chezmoi/chezmoi.toml"'
  - su - gabrielpedepera -c 'export PATH="$HOME/.local/bin:$PATH" && chezmoi init --apply gabrielpedepera/dotfiles'
''')
    }
    networkProfile: {
      networkInterfaces: [{ id: nic.id, properties: { deleteOption: 'Delete' } }]
    }
  }
}

resource autoShutdown 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: { time: '1900' }
    timeZoneId: 'UTC'
    targetResourceId: vm.id
    notificationSettings: { status: 'Disabled' }
  }
}
