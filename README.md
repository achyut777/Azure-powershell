☁️ Azure VM Automation using PowerShell

🚀 Create & delete Azure Virtual Machines with one command
Perfect for AZ-104, hands-on labs, and real-world automation practice.

📌 What is this repo?

This repository provides PowerShell automation scripts to:

✅ Create an Azure Linux VM
✅ Automatically configure networking
✅ Cleanly delete all resources (no leftover costs 💸)

Designed for:

🧑‍🎓 AZ-104 learners

☁️ Cloud beginners

⚙️ Automation practice

📂 Repository Structure
📁 azure-vm-powershell
├── 🖥️ vm.ps1            # Create Azure VM
├── 🗑️ delete-vm.ps1     # Delete all resources safely
├── 📘 README.md
└── 📄 LICENSE

⚙️ Prerequisites

Make sure you have:

✅ Active Azure Subscription

✅ Azure PowerShell (Az module)

✅ Logged in to Azure

Connect-AzAccount


💡 Tip: These scripts work perfectly in Azure Cloud Shell (PowerShell mode).

🚀 Create Azure Virtual Machine

The vm.ps1 script automatically creates:

🧱 Resource Group
🌐 Virtual Network & Subnet
🛡️ Network Security Group
🔓 SSH access (Port 22)
🖥️ Ubuntu 22.04 VM
🌍 Public IP Address

▶️ Run the script
./vm.ps1


⏳ VM creation usually takes 2–5 minutes.

🗑️ Delete Azure Resources (Highly Recommended)

Avoid unexpected Azure charges 💸
Use delete-vm.ps1 to delete EVERYTHING safely.

❌ What gets deleted?

🖥️ Virtual Machine

💾 OS Disk

🔌 Network Interface

🌍 Public IP

🛡️ NSG

🌐 VNet

▶️ Run cleanup script
./delete-vm.ps1


⚠️ Warning: This action is permanent.

🧠 AZ-104 Exam Tips

📌 New-AzVM is a high-level cmdlet
📌 Azure auto-creates networking if not provided
📌 Best way to remove a VM? → Delete the Resource Group
📌 PowerShell scripts always use .ps1

🐧 Platform Support

✔ Windows PowerShell
✔ PowerShell Core (Linux/macOS)
✔ Azure Cloud Shell

🎯 Why use this repo?

✨ Beginner-friendly
✨ Real AZ-104 aligned tasks
✨ Clean resource cleanup
✨ Industry-relevant automation

👤 Author

Achyut Hadavani
☁️ Cloud | 🐧 Linux | ⚙️ DevOps Enthusiast

🔗 Learning Azure the practical way.

⭐ Like this repo?

If this helped you:

⭐ Star the repository

🍴 Fork it

📢 Share with AZ-104 learners