# VARIABLES
$resourceGroup = "Symbiosis-RG"
$location = "CentralIndia"
$vmName = "symbiosis-vm"
$vmSize = "Standard_B1s"
$adminUser = "azureuser"
$sshKeyPath = "$HOME\.ssh\id_rsa.pub"
$repoUrl = "https://github.com/Jani-shiv/Symbiosis-Heckathon.git"

# CREATE RESOURCE GROUP
New-AzResourceGroup -Name $resourceGroup -Location $location

# CREATE VIRTUAL NETWORK
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-vnet" `
  -AddressPrefix "10.0.0.0/16"

$subnet = Add-AzVirtualNetworkSubnetConfig `
  -Name "symbiosis-subnet" `
  -AddressPrefix "10.0.1.0/24" `
  -VirtualNetwork $vnet

$vnet | Set-AzVirtualNetwork

# CREATE NSG (ALLOW SSH & HTTP)
$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-nsg"

$nsg | Add-AzNetworkSecurityRuleConfig `
  -Name "Allow-SSH" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix "*" `
  -SourcePortRange "*" `
  -DestinationAddressPrefix "*" `
  -DestinationPortRange 22 `
  -Access Allow

$nsg | Add-AzNetworkSecurityRuleConfig `
  -Name "Allow-HTTP" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1010 `
  -SourceAddressPrefix "*" `
  -SourcePortRange "*" `
  -DestinationAddressPrefix "*" `
  -DestinationPortRange 80 `
  -Access Allow

$nsg | Set-AzNetworkSecurityGroup

# CREATE PUBLIC IP
$publicIp = New-AzPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-ip" `
  -AllocationMethod Static

# CREATE NIC
$nic = New-AzNetworkInterface `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-nic" `
  -SubnetId $vnet.Subnets[0].Id `
  -NetworkSecurityGroupId $nsg.Id `
  -PublicIpAddressId $publicIp.Id

# VM CONFIG
$vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

$vmConfig = Set-AzVMOperatingSystem `
  -VM $vmConfig `
  -Linux `
  -ComputerName $vmName `
  -Credential (Get-Credential -Message "Enter VM username & password") `
  -DisablePasswordAuthentication:$false

$vmConfig = Set-AzVMSourceImage `
  -VM $vmConfig `
  -PublisherName Canonical `
  -Offer UbuntuServer `
  -Skus 22_04-lts `
  -Version latest

$vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

# CREATE VM
New-AzVM `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -VM $vmConfig

# INSTALL NGINX + DEPLOY WEBSITE
$script = @"
sudo apt update -y
sudo apt install nginx git -y
sudo rm -rf /var/www/html/*
sudo git clone $repoUrl /var/www/html
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart nginx
"@

Invoke-AzVMRunCommand `
  -ResourceGroupName $resourceGroup `
  -VMName $vmName `
  -CommandId "RunShellScript" `
  -ScriptString $script
