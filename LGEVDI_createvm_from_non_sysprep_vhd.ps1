# Variables for common values
$resourceGroup = "ctxbaserg"
$location = "koreacentral"
$vmName = "ctxeubasevm"
$computername = "ctxeubasevm"
$vnetname = "KoreaCentralvNET"
$vnetResourceGroup = "KoreaCentralvNETrg"
$vmsize = "Standard_F4s"
#$vmsize = "Standard_D1_v2"
$nsgname = $computername + "nsg"
$storageaccountname = "secappsa"
$vnetAddressPrefix = "10.1.103.0/25"
$subnetAddressPrefix = "10.1.103.0/25"
$nicVM1Name = $computername + "Nic1"
$availabilitySetName = $computername+"AvSet"
$osDiskName = $vmName + "osDisk"
$imageName = $computername + "Base"
# Create user object
#$cred = Get-Credential -Message "Enter a username and password for the virtual machine."

# User credential can be used to login to Azure or can be used to set credential for VM
#$azureAccountName ="wvdadmin"
#$azurePassword = ConvertTo-SecureString "corpad@2019!" -AsPlainText -Force
#$psCred = New-Object System.Management.Automation.PSCredential($azureAccountName, $azurePassword)

# Login-AzureRmAccount -Credential $psCred
#Install-Module -Name AzureRM -RequiredVersion 3.5.0
Login-AzureRmAccount
#Select the right subscription
Get-AzureRmSubscription -SubscriptionName "SEC_WVD_PoC" | Select-AzureRmSubscription
#Get-AzureRmSubscription -SubscriptionName "Visual Studio Enterprise" | Select-AzureRmSubscription

# Create a resource group, if there isn't one.
# New-AzureRmResourceGroup -Name $resourceGroup -Location $location

<#
# Create a Storage Account. Standard LRS
New-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageaccountname `
  -Type "Premium_LRS" `
  -Location $location 
#>
 
<#
New-AzureRmStorageAccount -ResourceGroupName $resourceGroup `
  -Name $storageaccountname `
  -Location $location `
  -SkuName Standard_LRS `
  -Kind Storage
#>
<#
# Configuring Custom Image
$osDiskVhdUri = "https://vhdtransfer.blob.core.windows.net/vhds/Win2cdrive.vhd"
$imageConfig = New-AzureRmImageConfig -Location 'Southeast Asia'
#>
<#
$dataDiskVhdUri1 = "https://vhdtransfer.blob.core.windows.net/vhds/data1.vhd"
$dataDiskVhdUri2 = "https://vhdtransfer.blob.core.windows.net/vhds/data2.vhd"
#>
<#
Set-AzureRmImageOsDisk -Image $imageConfig -OsType 'Windows' -OsState 'Generalized' -BlobUri $osDiskVhdUri
#>
<#
Add-AzureRmImageDataDisk -Image $imageConfig -Lun 1 -BlobUri $dataDiskVhdUri1;
Add-AzureRmImageDataDisk -Image $imageConfig -Lun 2 -BlobUri $dataDiskVhdUri2;
#>
<#
$image = New-AzureRmImage -Image $imageConfig -ImageName $imageName -ResourceGroupName $resourceGroup
$image = Get-AzureRmImage -ImageName $imageName -ResourceGroupName $resourceGroup
#>
<#
$imageConfig = New-AzureRmImageConfig -Location 'Southeast Asia' | `
Set-AzureRmImageOsDisk -OsType 'Windows' -OsState 'Generalized' -BlobUri $osDiskVhdUri
$image = New-AzureRmImage -Image $imageConfig -ImageName $imageName -ResourceGroupName $resourceGroup
#>

# Create a subnet configuration, if required to create new vnet and subnet. if not select proper subnet.
#$subnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name workloadsubnet -AddressPrefix $subnetAddressPrefix

# Create a virtual network, if require to create a new vnet.
#$vnet = New-AzureRmVirtualNetwork -ResourceGroupName $resourceGroup -Location $location `
#  -Name $vnetname -AddressPrefix $vnetAddressPrefix -Subnet $subnetConfig

#if leveraging existing vnet, uncomment following command let.
$vnet = Get-AzureRmVirtualNetwork -Name $vnetname -ResourceGroupName $vnetResourceGroup
$subnet=$vnet.Subnets[2]

# Create a public IP address and specify a DNS name
#$pipName = $vmName + $(Get-Random -Minimum 10000 -Maximum 99999).tostring()
#$pip = New-AzureRmPublicIpAddress -ResourceGroupName $resourceGroup -Location $location `
#  -Name $pipName -AllocationMethod Static -IdleTimeoutInMinutes 4

# Create an inbound network security group rule for port 3389
$nsgRuleRDP = New-AzureRmNetworkSecurityRuleConfig -Name AllowRDPon3389  -Protocol Tcp `
  -Direction Inbound -Priority 1000 -SourceAddressPrefix Internet -SourcePortRange * -DestinationAddressPrefix * `
  -DestinationPortRange 3389 -Access Allow

# Create a network security group
$nsg = New-AzureRmNetworkSecurityGroup -ResourceGroupName $resourceGroup -Location $location `
  -Name $nsgname -SecurityRules $nsgRuleRDP

# Create three virtual network cards and associate with public IP address and NSG.
$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $location `
  -Name $nicVM1Name -NetworkSecurityGroupid $nsg.id -Subnetid $vnet.Subnets[2].id
#  -Name $nicVM1Name -NetworkSecurityGroupid $nsg.id -Subnetid $vnet.Subnets[0].id -PublicIpAddressid $pip.Id
<#
# Create three virtual network cards and associate with private IP address and NSG.
$nicVM1 = New-AzureRmNetworkInterface -ResourceGroupName $resourceGroup -Location $location `
  -Name "vhdtest4545_Nic1" -NetworkSecurityGroup $nsg -Subnet $vnet.Subnets[0]
#>
<#
$availabilitySet = New-AzureRmAvailabilitySet `
   -Location $location `
   -Name $availabilitySetName `
   -ResourceGroupName $resourceGroup `
   -sku aligned `
   -PlatformFaultDomainCount 2 `
   -PlatformUpdateDomainCount 5
#>

# Custom image on OS Drive 
# Create a virtual machine configuration

<#

$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize -AvailabilitySetId $availabilitySet.Id | `
  Set-AzureRmVMOperatingSystem -Windows -ComputerName $computername -Credential $PScred | `
  Set-AzureRmVMOSDisk -Name "converted.vhd" -VhdUri "https://vhdtransfer.blob.core.windows.net/vhds/" `
     -CreateOption Attach -Windows -Caching ReadOnly | Add-AzureRmVMNetworkInterface -Id $nicVM1.Id
#>
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize | Add-AzureRmVMNetworkInterface -Id $nicVM1.Id
$vmConfig = Set-AzureRmVMOSDisk -vm $vmConfig -Name "ctxbaseos" -CreateOption attach -VhdUri "https://secappsa.blob.core.windows.net/ctxvhd/ctxkrbasevm_master001.vhd" -Windows -Caching ReadOnly
#$vmConfig = Set-AzureRmVMOSDisk -vm $vmConfig -Name "ctxbaseos" -CreateOption attach -VhdUri "https://secappsa.blob.core.windows.net/ctxvhd/ctxkrbasevm_master001.vhd" -Linux -Caching ReadOnly
#Need to remove extension from portal and add back on the vm with PoSH
#Set-AzureRmVMAccessExtension -ResourceGroupName $resourceGroup -Location $location -VMName $vmName -Name "ContosoTest" -TypeHandlerVersion "2.0"
#Set-AzureRmVMBginfoExtension -ResourceGroupName $resourceGroup -VMName $vmName -Name "BGInfo" -TypeHandlerVersion "2.1" -Location $location

<#
$vmConfig = New-AzureRmVMConfig -VMName $vmName -VMSize $vmsize | `
Set-AzureRmVMOperatingSystem -Windows -ComputerName $computername -Credential $PScred | `
Set-AzureRmVMSourceImage -Id $image.Id |`
Add-AzureRmVMNetworkInterface -Id $nicVM1.Id
#>
$vm1 = New-AzureRmVM -ResourceGroupName $resourceGroup -Location $location -VM $vmConfig

###########################################################################################################
# To clean up the environment, do following command
#remove-azurermresourcegroup -name $resourceGroup -force

