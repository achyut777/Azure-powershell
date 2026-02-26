# ==============================
# LOGIN
# ==============================
Connect-AzAccount

# ==============================
# VARIABLES
# ==============================
$resourceGroup = "Symbiosis-RG"
$location      = "CentralIndia"
$vmName        = "symbiosis-vm"
$vmSize        = "Standard_B1s"
$repoUrl       = "https://github.com/Jani-shiv/Symbiosis-Heckathon.git"

# ==============================
# RESOURCE GROUP
# ==============================
New-AzResourceGroup `
  -Name $resourceGroup `
  -Location $location `
  -Force

# ==============================
# VNET + SUBNET
# ==============================
$vnet = New-AzVirtualNetwork `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-vnet" `
  -AddressPrefix "10.0.0.0/16"

Add-AzVirtualNetworkSubnetConfig `
  -Name "symbiosis-subnet" `
  -AddressPrefix "10.0.1.0/24" `
  -VirtualNetwork $vnet

$vnet | Set-AzVirtualNetwork

# Reload VNET (IMPORTANT)
$vnet     = Get-AzVirtualNetwork -Name "symbiosis-vnet" -ResourceGroupName $resourceGroup
$subnetId = $vnet.Subnets[0].Id

# ==============================
# NSG (SSH + HTTP)
# ==============================
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
  -DestinationPortRange 22 `
  -Access Allow

$nsg | Add-AzNetworkSecurityRuleConfig `
  -Name "Allow-HTTP" `
  -Protocol Tcp `
  -Direction Inbound `
  -Priority 1010 `
  -SourceAddressPrefix "*" `
  -SourcePortRange "*" `
  -DestinationPortRange 80 `
  -Access Allow

$nsg | Set-AzNetworkSecurityGroup

# ==============================
# PUBLIC IP
# ==============================
$publicIp = New-AzPublicIpAddress `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-ip" `
  -AllocationMethod Static `
  -Sku Basic

# ==============================
# NIC
# ==============================
$nic = New-AzNetworkInterface `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -Name "symbiosis-nic" `
  -SubnetId $subnetId `
  -NetworkSecurityGroupId $nsg.Id `
  -PublicIpAddressId $publicIp.Id

# ==============================
# VM CONFIG
# ==============================
$cred = Get-Credential -Message "Enter VM username & password"

$vmConfig = New-AzVMConfig `
  -VMName $vmName `
  -VMSize $vmSize

$vmConfig = Set-AzVMOperatingSystem `
  -VM $vmConfig `
  -Linux `
  -ComputerName $vmName `
  -Credential $cred `
  -DisablePasswordAuthentication:$false

# Ubuntu 22.04 (Region-safe image)
$vmConfig = Set-AzVMSourceImage `
  -VM $vmConfig `
  -PublisherName "Canonical" `
  -Offer "0001-com-ubuntu-server-jammy" `
  -Skus "22_04-lts" `
  -Version "latest"

# 🔴 IMPORTANT: Disable Trusted Launch
$vmConfig.SecurityProfile = @{
    SecurityType = "Standard"
}

$vmConfig = Add-AzVMNetworkInterface `
  -VM $vmConfig `
  -Id $nic.Id

# ==============================
# CREATE VM
# ==============================
New-AzVM `
  -ResourceGroupName $resourceGroup `
  -Location $location `
  -VM $vmConfig

# ==============================
# INSTALL NGINX + DEPLOY WEBSITE
# ==============================
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
