#Login-AzureRmAccount -Credential $psCred
Login-AzureRmAccount

#Select correct subscription if you have multiple subscriptions.
Get-AzureRmSubscription -SubscriptionName "Microsoft Azure Internal Consumption" | Select-AzureRmSubscription

#List all avaiable location
Get-AzureRmLocation | ft

#List all Compute SKUs in eastus2
Get-AzureRmComputeResourceSku | where {$_.Locations.Contains("eastus2")};

#Find out Compute what SKUs are available for this location.  
Get-AzureRmVMSize -location $location

# Variables for common values
$resourceGroup = 'lsglobalwebrg'
$vNetresourceGroup ='vnetrgname'
$location = 'eastus2'
$vmName = "webserver4545"
$computername = "webserver4545"
$vnetname = 'webservertestvNet'
$vmsize = 'Standard_D2_v3'
#$vmsize = 'Standard_D1_v2'
#$storageaccountname = "webservertest4545"
$vnetAddressPrefix = "172.18.0.0/16"
$subnetAddressPrefix = "172.18.3.0/24"
$nicVM1Name = $computername + "Nic1"
$availabilitySetName = $computername+"AvSet"
$zone = 1



#Publisher names
Get-AzureRmVMImagePublisher -Location $location

#OpenLogic
#$pubName="OpenLogic"
$pubName="MicrosoftWindowsServer"
Get-AzureRMVMImageOffer -Location $location -Publisher $pubName | Select Offer

#$offerName="CentOS"
$offerName="WindowsServer"
Get-AzureRMVMImageSku -Location $location -Publisher $pubName -Offer $offerName | Select Skus

#$skuName="7.5"
$skuName="2016-Datacenter"
Get-AzureRMVMImage -Location $location -Publisher $pubName -Offer $offerName -Sku $skuName | Select Version

#$version="7.5.20180815"
$version="2016.127.20190603"
Get-AzureRMVMImage -Location $location -Publisher $pubName -Offer $offerName -Sku $skuName -Version $version


# Create user object
#$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

$azureAccountName ="kunho.ko"
$azurePassword = ConvertTo-SecureString "CitrixOn" -AsPlainText -Force
$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)


# Create a resource group, if there isn't one.
New-AzureRmResourceGroup -Name $resourceGroup -Location $location

# Create a Storage Account. Standard LRS
New-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageaccountname `
  -Type "Premium_LRS" `
  -Location $location 
   
<#
New-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageaccountname `
  -Location $location `
  -SkuName Standard_LRS `
  -Kind Storage

#>

# Create a subnet configuration, if required to create new vnet and subnet. if not select proper subnet.
$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name workloadsubnet -AddressPrefix $subnetAddressPrefix

# Create a virtual network, if require to create a new vnet.
$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $vNetresourceGroup -Location $location `
  -Name $vnetname -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig

#if leveraging existing vnet, uncomment following command let.
#$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $resourceGroup
$subnet=$vnet.Subnets[0]

# Create a public IP address and specify a DNS name
$pipName = $vmName + $(Get-Random -Minimum 10000 -Maximum 99999).tostring()
$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
  -Name $pipName -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name AllowRDPon3389  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name DSVMNetworkSecurityGroup -SecurityRules $nsgRuleRDP

# Create three virtual network cards and associate with public IP address and NSG.
$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $location `
  -Name $nicVM1Name -NetworkSecurityGroupid $nsg.id -Subnetid $vnet.Subnets[0].id -PublicIpAddressid $pip.Id

<#
# Create three virtual network cards and associate with private IP address and NSG.
$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $location `
  -Name "vhdtest4545_Nic1" -NetworkSecurityGroup $nsg -Subnet $vnet.Subnets[0]
#>

$availabilitySet = New-AzureRmAvailabilitySet `
   -Location $location `
   -Name $availabilitySetName `
   -ResourceGroupName $resourceGroup `
   -sku aligned `
   -PlatformFaultDomainCount 2 `
   -PlatformUpdateDomainCount 5


# Custom image on OS Drive 
# Create a virtual machine configuration
<#
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availabilitySet.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName $computername -Credential $PScred | `
  Set-AzureRmVMOSDisk -Name "osDisk.vhd" -VhdUri "https://mystorageaccount.blob.core.windows.net/disks/" `
     -CreateOption Attach -Windows -Caching ReadOnly | Add-AzureRmVMNetworkInterface -Id $nicVM1.Id
#>

# Create a virtual machine configuration with Azure Hybrid Used Benefit enabled
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -LicenseType "Windows_Server" -Zone $zone | `
#$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availabilitySet.Id | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName $computername -Credential $PScred | `
Set-AzureRmVMSourceImage -PublisherName $pubName -Offer $offerName -Skus $skuName -Version $version | `
Add-AzureRmVMNetworkInterface -Id $nicvm1.Id


$vm1 = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

###########################################################################################################

remove-azurermresourcegroup -name $resourceGroup -force
