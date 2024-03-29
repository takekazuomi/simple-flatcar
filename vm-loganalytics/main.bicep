@description('The name of you Virtual Machine.')
param vmName string = 'simpleflatcar'

@description('Username for the Virtual Machine.')
param adminUsername string = 'core'

@description('SSH Key for the Virtual Machine.')
@secure()
param adminSshKey string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('simpleflatcar-${uniqueString(resourceGroup().id)}')

@description('Location for all resources.')
param location string = resourceGroup().location

@description('The size of the VM')
param vmSize string = 'Standard_B1s'

@description('Name of the VNET')
param virtualNetworkName string = 'vnet'

@description('Name of the subnet in the virtual network')
param subnetName string = 'subnet'

@description('Name of the Network Security Group')
param networkSecurityGroupName string = 'nsg'

@description('igni')
param customData string

@description('ssh access source ip address prefix.')
param sourceAddressPrefix string = '*'

@description('vmss or vm flag.')
param isVmss bool = false

var laName = '${replace(resourceGroup().name, '-rg','')}-log-analytics-workspace'

module vm '../vm/main.bicep' = if(isVmss) {
  name: 'vm'
  params: {
    vmName: vmName
    adminUsername: adminUsername
    adminSshKey: adminSshKey
    dnsLabelPrefix: dnsLabelPrefix
    location: location
    vmSize: vmSize
    virtualNetworkName: virtualNetworkName
    subnetName: subnetName
    networkSecurityGroupName: networkSecurityGroupName
    customData: customData
    sourceAddressPrefix: sourceAddressPrefix
  }
}

module vmss '../vmss/main.bicep' = if(isVmss) {
  name: 'vmss'
  params: {
    vmssName: vmName
    adminUsername: adminUsername
    adminSshKey: adminSshKey
    location: location
    vmSku: vmSize
    customData: customData
    sourceAddressPrefix: sourceAddressPrefix
    instanceCount:1
    publicIPPrefixLength:31
  }
}

resource la 'microsoft.operationalinsights/workspaces@2020-10-01' = {
  name: laName
  location: location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: 30
    workspaceCapping: {
      dailyQuotaGb: -1
    }
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
  }
}

var slnName = 'Containers(${la.name})'

resource sln 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: slnName
  location: location
  plan: {
    name: slnName
    product: 'OMSGallery/Containers'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  properties: {
    workspaceResourceId: la.id
  }
}

output adminUsername string = vm.outputs.adminUsername
output hostname string = isVmss ? vm.outputs.hostName : ''
output sshCommand string = isVmss ? vm.outputs.sshCommand : vmss.outputs.sshCommand
output workspaceName string = la.name
output workspaceId string = la.properties.customerId
output workspaceKey string = listKeys(la.id, la.apiVersion).primarySharedKey
