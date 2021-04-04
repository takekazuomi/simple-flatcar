@description('SSH Key for the Virtual Machine.')
@secure()
param adminSshKey string

@description('Admin username on all VMs.')
param adminUsername string = 'core'

@minValue(1)
@maxValue(100)
@description('Number of VM instances (100 or less).')
param instanceCount int = 1

@description('Location for resources. Default is the current resource group location.')
param location string = resourceGroup().location

@minValue(28)
@maxValue(31)
@description('Length of public IP prefix.')
param publicIPPrefixLength int = 31

@description('Size of VMs in the VM Scale Set.')
param vmSku string = 'Standard_B1s'

@maxLength(9)
@description('String used as a base for naming resources (9 characters or less). A hash is prepended to this string for some resources, and resource-specific information is appended.')
param vmssName string = 'vmss'

@description('igni')
param customData string

@description('ssh access source ip address prefix.')
param sourceAddressPrefix string = '*'

@description('has public ip each vm.')
param hasPublicIp bool = true

var addressPrefix = '10.0.0.0/16'
var bePoolName = '${vmssName}-bepool'
var dnsName = '${toLower(vmssName)}-${uniqueString(resourceGroup().id)}'
var frontEndIPConfigID = resourceId('Microsoft.Network/loadBalancers/frontendIPConfigurations', loadBalancerName, 'loadBalancerFrontEnd')
var imageReference = osType
var ipConfigName = '${vmssName}-ipconfig'
var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${adminUsername}/.ssh/authorized_keys'
        keyData: adminSshKey
      }
    ]
  }
}

var loadBalancerName = '${vmssName}-lb'
var natBackendPort = 22
var natPoolName = '${vmssName}-natpool'
var natStartPort = 50000
var natEndPort = 50120
var nicName = '${vmssName}-nic'
var osType = {
  publisher: 'kinvolk'
  offer: 'flatcar-container-linux-free'
  sku: 'stable'
  version: 'latest'
}

var publicIPAddressName = '${vmssName}-pip'
var publicIPPrefixName = '${vmssName}-pubipprefix'
var subnetName = '${vmssName}-subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = '${vmssName}-vnet'
var networkSecurityGroupName = '${vmssName}-nsg'

resource vmss 'Microsoft.Compute/virtualMachineScaleSets@2020-12-01' = {
  name: vmssName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: instanceCount
  }
  plan: {
    name: 'stable'
    publisher: 'kinvolk'
    product: 'flatcar-container-linux-free'
  }
  properties: {
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      storageProfile: {
        osDisk: {
          caching: 'ReadOnly'
          createOption: 'FromImage'
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
          diskSizeGB: 30
        }
        imageReference: imageReference
      }
      osProfile: {
        computerNamePrefix: vmssName
        adminUsername: adminUsername
        adminPassword: adminSshKey
        linuxConfiguration: linuxConfiguration
        customData: customData
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: nicName
            properties: {
              primary: true
              ipConfigurations: [
                {
                  name: ipConfigName
                  properties: {
                    subnet: {
                      id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
                    }
                    publicIPAddressConfiguration: any(hasPublicIp ? {
                      name: 'pub1'
                      properties: {
                        idleTimeoutInMinutes: 15
                        publicIPPrefix: {
                          id: pipPrefix.id
                        }
                      }
                    } : null)
                    loadBalancerBackendAddressPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/backendAddressPools', loadBalancerName, bePoolName)
                      }
                    ]
                    loadBalancerInboundNatPools: [
                      {
                        id: resourceId('Microsoft.Network/loadBalancers/inboundNatPools', loadBalancerName, natPoolName)
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
  dependsOn: [
    lb
    vnet
  ]
}

resource lb 'Microsoft.Network/loadBalancers@2020-08-01' = {
  name: loadBalancerName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    frontendIPConfigurations: [
      {
        name: 'LoadBalancerFrontEnd'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
    ]
    backendAddressPools: [
      {
        name: bePoolName
      }
    ]
    inboundNatPools: [
      {
        name: natPoolName
        properties: {
          frontendIPConfiguration: {
            id: frontEndIPConfigID
          }
          protocol: 'Tcp'
          frontendPortRangeStart: natStartPort
          frontendPortRangeEnd: natEndPort
          backendPort: natBackendPort
        }
      }
    ]
  }
}

resource pip 'Microsoft.Network/publicIPAddresses@2020-08-01' = {
  name: publicIPAddressName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
    dnsSettings: {
      domainNameLabel: dnsName
    }
  }
}

resource pipPrefix 'Microsoft.Network/publicIPPrefixes@2020-08-01' = if (hasPublicIp) {
  name: publicIPPrefixName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    prefixLength: publicIPPrefixLength
    publicIPAddressVersion: 'IPv4'
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2020-08-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-08-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: sourceAddressPrefix
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '22'
        }
      }
    ]
  }
}

output adminUsername string = adminUsername
output sshCommand string = 'ssh ${adminUsername}@${pip.properties.ipAddress}'
output vmss object = vmss
output pipPrefix object = hasPublicIp ? pipPrefix : {}
output ipAddresses array = hasPublicIp ? pipPrefix.properties.publicIPAddresses : []
