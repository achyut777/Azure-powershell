# =====================================================
# Azure VM + Website Deployment (Azure for Students)
# Ubuntu 22.04 Gen2 + Trusted Launch
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

# ---------------- NSG (Allow HTTP) ----------------
$nsg = Get-AzNetworkSecurityGroup -Name $nsgName -ResourceGroupName $rg -ErrorAction SilentlyContinue

if (-not $nsg) {

    $ruleHTTP = New-AzNetworkSecurityRuleConfig `
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
        -SecurityRules $ruleHTTP
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

# ---------------- VM CONFIG ----------------
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

# Remove default Apache page
sudo rm -rf /var/www/html/*

# Clone GitHub repo
sudo git clone https://github.com/Jani-shiv/Symbiosis-Heckathon.git /tmp/site

# Move website files
sudo mv /tmp/site/* /var/www/html/

# Fix permissions
sudo chown -R www-data:www-data /var/www/html
sudo chmod -R 755 /var/www/html

sudo systemctl enable apache2
sudo systemctl restart apache2
"@

# ---------------- OUTPUT PUBLIC IP ----------------
$ip = (Get-AzPublicIpAddress -ResourceGroupName $rg -Name $ipName).IpAddress

Write-Host "==========================================="
Write-Host "✅ VM CREATED & WEBSITE DEPLOYED SUCCESSFULLY"
Write-Host "🌍 Open this in browser:"
Write-Host "http://$ip"
Write-Host "==========================================="
