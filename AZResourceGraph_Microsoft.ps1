* To find VM cost recommendations

advisorresources
    | where type == 'microsoft.advisor/recommendations'
    | where properties.category == 'Cost'
    | where properties.impactedField =~ 'Microsoft.Compute/virtualMachines'
    | project VM=properties.impactedValue, Current=properties.extendedProperties.currentSku, Target=properties.extendedProperties.targetSku, MaxCPUP95=properties.extendedProperties.MaxCpuP95, MaxMemoryP95=properties.extendedProperties.MaxMemoryP95, MaxNetworkP95=properties.extendedProperties.MaxTotalNetworkP95,subscription=subscriptionId
    | order by subscription asc


* Find VM by guest name

Resources
	| where type =~ 'Microsoft.Compute/virtualMachines'
	| where properties.osProfile.computerName =~ 'savazuusscdc01' or properties.extended.instanceView.computerName =~ 'savazuusscdc01'
	| join (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
	| project VMName = name, CompName = properties.osProfile.computerName, OSType =  properties.storageProfile.osDisk.osType, RGName = resourceGroup, SubName, SubID = subscriptionId


* Unused Managed Disks

Resources | 
    where type =~ 'Microsoft.Compute/disks' | 
    where managedBy =~ '' | 
    project name, resourceGroup, subscriptionId, location, tags, sku.name, id


* Unused Public IPs

Resources | 
    where type =~ 'Microsoft.Network/publicIPAddresses' |
    where properties.ipConfiguration =~ '' |
    project name, resourceGroup, subscriptionId, location, tags, id


* VMSS Autoscale

Resources
    | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
    | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | project VMMSName = name, RGName = resourceGroup, VMMSSKU = sku.name, VMMSCount = sku.capacity, SubName, SubID = subscriptionId, ResID = id

#Link to scale action
Resources
    | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
    | extend lowerId = tolower(id)
    | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | join kind=leftouter (Resources | where type=='microsoft.insights/autoscalesettings' | project ScaleName=tostring(properties.name),lowerId=tolower(tostring(properties.targetResourceUri))) on lowerId
    | project VMMSName = name, RGName = resourceGroup, VMMSSKU = sku.name, VMMSCount = sku.capacity, SubName, SubID = subscriptionId, ResID = id, ScaleName

#Just scale actions
Resources
    | where type=='microsoft.insights/autoscalesettings'
    | where properties.targetResourceUri contains 'virtualmachinescalesets'

#With some information about the scale
Resources
    | where type =~ 'Microsoft.Compute/virtualMachineScaleSets'
    | extend lowerId = tolower(id)
    | join kind=inner (ResourceContainers | where type=='microsoft.resources/subscriptions' | project SubName=name, subscriptionId) on subscriptionId
    | join kind=leftouter (Resources | where type=='microsoft.insights/autoscalesettings' | project ScaleName=tostring(properties.name), minCount=properties.profiles[0].capacity.minimum, maxCount=properties.profiles[0].capacity.maximum,lowerId=tolower(tostring(properties.targetResourceUri))) on lowerId
    | project VMMSName = name, RGName = resourceGroup, VMMSSKU = sku.name, VMMSCount = sku.capacity, SubName, SubID = subscriptionId, ResID = id, ScaleName, minCount, maxCount
