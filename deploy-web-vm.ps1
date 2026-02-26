# =====================================================
# Azure VM + Website Deployment (Azure for Students)
# Trusted Launch + Gen2 Image (WORKING)
# =====================================================

Connect-AzAccount -UseDeviceAuthentication

# ---------------- VARIABLES ----------------
$rg        = "Symbiosis-RG"
$location  = "centralindia"

$vnetName   = "symbiosis-vnet"
$subnetName = "symbiosis-subnet"
$nsgName    = "symbiosis-nsg"
$ipName     = "symbiosis-ip"
$nicName    = "symbiosis-nic"
$vmName     = "symbiosis-vm"

# ---------------- RESOURCE GROUP ----------------
if (-not (Get-AzResourceGroup -Name $rg -ErrorAction SilentlyContinue)) {
    New-AzResourceGroup -Name $rg -Location $location
}

# ---------------- VNET & SUBNET ----------------
$vnet = Get-AzVirtualNetwork -Name $vnetName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $vnet) {
    $subnetConfig = New-AzVirtualNetworkSubnetConfig `
        -Name $subnetName `
        -AddressPrefix "10.0.1.0/24"

    $vnet = New-AzVirtualNetwork `
        -Name $vnetName `
        -ResourceGroupName $rg `
        -Location $location `
        -AddressPrefix "10.0.0.0/16" `
        -Subnet $subnetConfig
}

$subnet = $vnet.Subnets | Where-Object { $_.Name -eq $subnetName }

# ---------------- NSG ----------------
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $nsg) {
    $rule = New-AzNetworkSecurityRuleConfig `
        -Name "Allow-HTTP" `
        -Protocol Tcp `
        -Direction Inbound `
        -Priority 1000 `
        -SourceAddressPrefix "*" `
        -SourcePortRange "*" `
        -DestinationAddressPrefix "*" `
        -DestinationPortRange 80 `
        -Access Allow

    $nsg = New-AzNetworkSecurityGroup `
        -ResourceGroupName $rg `
        -Location $location `
        -Name $nsgName `
        -SecurityRules $rule
}

# ---------------- PUBLIC IP ----------------
$publicIp = Get-AzPublicIpAddress -Name $ipName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $publicIp) {
    $publicIp = New-AzPublicIpAddress `
        -Name $ipName `
        -ResourceGroupName $rg `
        -Location $location `
        -AllocationMethod Static `
        -Sku Standard
}

# ---------------- NIC ----------------
$nic = Get-AzNetworkInterface -Name $nicName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $nic) {
    $nic = New-AzNetworkInterface `
        -Name $nicName `
        -ResourceGroupName $rg `
        -Location $location `
        -SubnetId $subnet.Id `
        -PublicIpAddressId $publicIp.Id `
        -NetworkSecurityGroupId $nsg.Id
}

# ---------------- VM CREDENTIAL ----------------
$cred = Get-Credential

# ---------------- VM CONFIG (Trusted Launch Gen2) ----------------
$vmConfig = New-AzVMConfig `
    -VMName $vmName `
    -VMSize "Standard_B1s" `
    -SecurityType "TrustedLaunch"

$vmConfig = Set-AzVMOperatingSystem `
    -VM $vmConfig `
    -Linux `
    -ComputerName $vmName `
    -Credential $cred `
    -DisablePasswordAuthentication:$false

# ✅ GEN2 IMAGE (VERY IMPORTANT)
$vmConfig = Set-AzVMSourceImage `
    -VM $vmConfig `
    -PublisherName "Canonical" `
    -Offer "0001-com-ubuntu-server-jammy" `
    -Skus "22_04-lts-gen2" `
    -Version "latest"

$vmConfig = Add-AzVMNetworkInterface `
    -VM $vmConfig `
    -Id $nic.Id

# ---------------- CREATE VM ----------------
New-AzVM `
    -ResourceGroupName $rg `
    -Location $location `
    -VM $vmConfig

# ---------------- DEPLOY WEBSITE ----------------
Invoke-AzVMRunCommand `
    -ResourceGroupName $rg `
    -VMName $vmName `
    -CommandId "RunShellScript" `
    -ScriptString @"
sudo apt update -y
sudo apt install apache2 git -y
sudo rm -rf /var/www/html/*
sudo git clone https://github.com/Jani-shiv/Symbiosis-Heckathon.git /var/www/html
sudo systemctl restart apache2
"@

Write-Host "✅ VM CREATED & WEBSITE DEPLOYED SUCCESSFULLY"
