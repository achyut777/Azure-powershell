# =========================
# LOGIN
# =========================
Connect-AzAccount

# =========================
# VARIABLES
# =========================
$rg        = "Symbiosis-RG"
$location  = "CentralIndia"
$vmName    = "symbiosis-vm"
$vmSize    = "Standard_B1s"
$vnetName  = "symbiosis-vnet"
$subnetName= "symbiosis-subnet"
$nsgName   = "symbiosis-nsg"
$nicName   = "symbiosis-nic"
$ipName    = "symbiosis-ip"
$repoUrl   = "https://github.com/Jani-shiv/Symbiosis-Heckathon.git"

# =========================
# RESOURCE GROUP
# =========================
if (-not (Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rg -Location $location
}

# =========================
# VNET + SUBNET (REUSE SAFE)
# =========================
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $vnet) {
    $vnet = New-AzVirtualNetwork `
        -Name $vnetName `
        -ResourceGroupName $rg `
        -Location $location `
        -AddressPrefix "10.0.0.0/16"

    Add-AzVirtualNetworkSubnetConfig `
        -Name $subnetName `
        -AddressPrefix "10.0.1.0/24" `
        -VirtualNetwork $vnet | Set-AzVirtualNetwork
}

$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg
$subnetId = $vnet.Subnets[0].Id

# =========================
# NSG (REUSE SAFE)
# =========================
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $nsg) {
    $nsg = New-AzNetworkSecurityGroup `
        -Name $nsgName `
        -ResourceGroupName $rg `
        -Location $location

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
}

# =========================
# PUBLIC IP (REUSE SAFE)
# =========================
$publicIp = Get-AzPublicIpAddress -Name $ipName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $publicIp) {
    $publicIp = New-AzPublicIpAddress `
        -Name $ipName `
        -ResourceGroupName $rg `
        -Location $location `
        -AllocationMethod Static
}

# =========================
# NIC (REUSE SAFE)
# =========================
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $nic) {
    $nic = New-AzNetworkInterface `
        -Name $nicName `
        -ResourceGroupName $rg `
        -Location $location `
        -SubnetId $subnetId `
        -NetworkSecurityGroupId $nsg.Id `
        -PublicIpAddressId $publicIp.Id
}

# =========================
# VM (CREATE ONLY IF MISSING)
# =========================
$vm = Get-AzVM -Name $vmName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $vm) {

    $cred = Get-Credential -Message "Enter VM username & password"

    $vmConfig = New-AzVMConfig -VMName $vmName -VMSize $vmSize

    $vmConfig = Set-AzVMOperatingSystem `
        -VM $vmConfig `
        -Linux `
        -ComputerName $vmName `
        -Credential $cred `
        -DisablePasswordAuthentication:$false

    $vmConfig = Set-AzVMSourceImage `
        -VM $vmConfig `
        -PublisherName "Canonical" `
        -Offer "0001-com-ubuntu-server-jammy" `
        -Skus "22_04-lts" `
        -Version "latest"

    # 🔥 NO SecurityProfile AT ALL (fixes Trusted Launch error)
    $vmConfig = Add-AzVMNetworkInterface -VM $vmConfig -Id $nic.Id

    New-AzVM `
        -ResourceGroupName $rg `
        -Location $location `
        -VM $vmConfig
}

# =========================
# DEPLOY WEBSITE
# =========================
Invoke-AzVMRunCommand `
  -ResourceGroupName $rg `
  -VMName $vmName `
  -CommandId "RunShellScript" `
  -ScriptString @"
sudo apt update -y
sudo apt install nginx git -y
sudo rm -rf /var/www/html/*
sudo git clone $repoUrl /var/www/html
sudo chown -R www-data:www-data /var/www/html
sudo systemctl restart nginx
"@
