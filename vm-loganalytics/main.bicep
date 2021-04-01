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
param VmSize string = 'Standard_B1s'

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

var laName = '${replace(resourceGroup().name, '-rg','')}-log-analytics-workspace'

module vm '../vm/main.bicep' = {
  name: 'vm'
  params: {
    vmName: vmName
    adminUsername: adminUsername
    adminSshKey: adminSshKey
    dnsLabelPrefix: dnsLabelPrefix
    location: location
    VmSize: VmSize
    virtualNetworkName: virtualNetworkName
    subnetName: subnetName
    networkSecurityGroupName: networkSecurityGroupName
    customData: customData
    sourceAddressPrefix: sourceAddressPrefix
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
// param workspaces_log_analytics_workspace01_externalid string =
// '/subscriptions/eb366cce-61a4-447f-b5d0-cf4a7a262b37/resourceGroups/takekazuomi01-rg/providers/Microsoft.OperationalInsights/workspaces/log-analytics-workspace01'

resource sln 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: slnName
  location: location
  plan: {
    name: slnName
    product: 'OMSGallery/Containers'
    publisher: 'Microsoft'
  }
  properties: {
    workspaceResourceId: la.id
    containedResources: [
      '${la.id}/views/${slnName}'
    ]
  }
}

output adminUsername string = vm.outputs.adminUsername
output hostname string = vm.outputs.hostname
output sshCommand string = vm.outputs.sshCommand
