# Variables
$resourceGroup = "RG-Achyut"
$location      = "EastAsia"
$vmName        = "AchyutVM"
$vmSize        = "Standard_B1s"
$adminUser     = "azureuser"

# Create Resource Group
New-AzResourceGroup `
    -Name $resourceGroup `
    -Location $location

# Create VM (Azure will auto-create VNet, Subnet, NSG, Public IP)
New-AzVM `
    -ResourceGroupName $resourceGroup `
    -Name $vmName `
    -Location $location `
    -VirtualNetworkName "AchyutVNet" `
    -SubnetName "AchyutSubnet" `
    -SecurityGroupName "AchyutNSG" `
    -PublicIpAddressName "AchyutPublicIP" `
    -OpenPorts 22 `
    -Image "Ubuntu2204" `
    -Size $vmSize `
    -Credential (Get-Credential) `
    -Verbose
