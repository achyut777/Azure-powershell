# Variables
$resourceGroup = "RG-Achyut"

# Login (if not already logged in)
Connect-AzAccount

# Delete Resource Group (VM, VNet, NSG, IP, Disk – EVERYTHING)
Remove-AzResourceGroup `
    -Name $resourceGroup `
    -Force `
    -Verbose
