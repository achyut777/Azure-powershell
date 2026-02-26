# Login (skip if already logged in)
Connect-AzAccount

# ========================
# VARIABLES
# ========================
$rgName = "Symbiosis-RG"
$location = "CentralIndia"
$vmName = "symbiosis-vm"
$vmSize = "Standard_B1s"
$adminUser = "azureuser"
$sshKeyPath = "$HOME/.ssh/id_rsa.pub"

$repoUrl = "https://github.com/Jani-shiv/Symbiosis-Heckathon.git"

# ========================
# RESOURCE GROUP
# ========================
New-AzResourceGroup -Name $rgName -Location $location

# ========================
# NETWORK
# ========================
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $rgName `
  -Location $location `
  -Name "symbiosis-vnet" `
  -AddressPrefix "10.0.0.0/16"

$subnet = Add-AzVirtualNetworkSubnetConfig `
  -Name "symbiosis-subnet" `
  -AddressPrefix "10.0.1.0/24" `
  -VirtualNetwork $vnet

$vnet | Set-AzVirtualNetwork

$nsg = New-AzNetworkSecurityGroup `
  -ResourceGroupName $rgName `
  -Location $location `
  -Name "symbiosis-nsg"

$nsg | Add-AzNetworkSecurityRuleConfig `
  -Name "Allow-HTTP" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1000 `
  -SourceAddressPrefix * `
  -SourcePortRange * `
  -DestinationAddressPrefix * `
  -DestinationPortRange 80 `
  -Access Allow

$nsg | Set-AzNetworkSecurityGroup

$publicIp = New-AzPublicIpAddress `
  -ResourceGroupName $rgName `
  -Location $location `
  -Name "symbiosis-ip" `
  -AllocationMethod Static

$nic = New-AzNetworkInterface `
  -ResourceGroupName $rgName `
  -Location $location `
  -Name "symbiosis-nic" `
  -SubnetId $vnet.Subnets[0].Id `
  -PublicIpAddressId $publicIp.Id `
  -NetworkSecurityGroupId $nsg.Id

# ========================
# VM CONFIGURATION
# ========================
$vmConfig = New-AzVMConfig `
  -VMName $vmName `
  -VMSize $vmSize

$vmConfig = Set-AzVMOperatingSystem `
  -VM $vmConfig `
  -Linux `
  -ComputerName $vmName `
  -Credential (Get-Credential -UserName $adminUser -Message "Enter VM password")

$vmConfig = Set-AzVMSourceImage `
  -VM $vmConfig `
  -PublisherName "Canonical" `
  -Offer "0001-com-ubuntu-server-jammy" `
  -Skus "22_04-lts" `
  -Version "latest"

$vmConfig = Add-AzVMNetworkInterface `
  -VM $vmConfig `
  -Id $nic.Id

# ========================
# CREATE VM
# ========================
New-AzVM `
  -ResourceGroupName $rgName `
  -Location $location `
  -VM $vmConfig

# ========================
# INSTALL & DEPLOY WEBSITE
# ========================
$script = @"
sudo apt update -y
sudo apt install -y nginx git
sudo rm -rf /var/www/html/*
sudo git clone $repoUrl /var/www/html
sudo systemctl restart nginx
"@

Invoke-AzVMRunCommand `
  -ResourceGroupName $rgName `
  -VMName $vmName `
  -CommandId "RunShellScript" `
  -ScriptString $script

Write-Host "✅ Deployment Complete!"
