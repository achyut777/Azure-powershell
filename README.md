Azure VM Creation & Cleanup using PowerShell

This repository contains PowerShell scripts to create and delete an Azure Virtual Machine using the Az PowerShell module.
It is designed for AZ-104 (Azure Administrator) practice and hands-on learning.

📁 Repository Structure
.
├── vm.ps1          # Script to create an Azure VM
├── delete-vm.ps1   # Script to delete the Azure Resource Group
├── README.md
└── LICENSE

🚀 Prerequisites

Before running the scripts, make sure you have:

An active Azure subscription

Azure PowerShell (Az module) installed

Logged in to Azure:

Connect-AzAccount


You can also run these scripts directly in Azure Cloud Shell (PowerShell mode).

🖥️ Create Azure Virtual Machine

The script vm.ps1 performs the following actions:

Creates a Resource Group

Creates a Virtual Network & Subnet

Creates Network Security Group

Opens SSH (Port 22)

Creates a Linux VM (Ubuntu 22.04)

Assigns a Public IP

Run the script
./vm.ps1

🗑️ Delete Azure Resources (Cleanup)

To avoid unnecessary charges, delete all created resources using delete-vm.ps1.

This script deletes the entire Resource Group, including:

Virtual Machine

OS Disk

Network Interface

Public IP

NSG

Virtual Network

Run the cleanup script
./delete-vm.ps1


⚠️ Warning: This action is permanent and cannot be undone.

🧠 Notes for AZ-104 Exam

New-AzVM is a high-level cmdlet that can auto-create networking resources

Deleting a Resource Group is the safest way to remove all associated resources

PowerShell scripts use the .ps1 file extension

🐧 Cross-Platform Support

These scripts work on:

Windows PowerShell

PowerShell Core on Linux/macOS

Azure Cloud Shell

📌 Disclaimer

This repository is for learning and practice purposes only.
Always monitor your Azure resources to avoid unexpected costs.

👤 Author

Achyut Hadavani
Azure | Linux | Cloud & DevOps Enthusiast