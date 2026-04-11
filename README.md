# Azure Remote Development Infrastructure

This repository contains the Infrastructure as Code (Bicep) to deploy a high-performance Ubuntu 24.04 Pro development workstation in Azure. 

It is designed for a "client-server" workflow: your **MacBook Neo** acts as the interface (via VS Code), while a **Standard_D2s_v5** VM in North Europe handles the compute.

## 🚀 Features
- **Zero-Config Connection:** Uses a fixed DNS label (`ubuntu-dev-workstation.northeurope.cloudapp.azure.com`).
- **Ubuntu Pro 24.04:** Enterprise-grade Linux with long-term security patching.
- **Auto-Shutdown:** Automatically stops the VM at 19:00 UTC to minimize Azure costs.
- **Developer Stack:** Pre-configured with Docker, Node.js (LTS), Python3, and Zsh.

---

## 🛠 Prerequisites

### 1. Install Azure CLI
On your MacBook Neo, install the CLI using Homebrew:

```bash
brew update && brew install azure-cli
```

### 2. Prepare your SSH Key
Using your existing `.pem` key pair, extract the public "lock" string for Azure:

```bash
# Set strict permissions (Required by macOS)
chmod 400 ~/.ssh/your-key-pair.pem

# Extract the Public Key string for the deployment command
ssh-keygen -y -f ~/.ssh/your-key-pair.pem
```

---

## 📦 Deployment Instructions

### 1. Authenticate
```bash
az login
az account set --subscription "<your-subscription-id>"
```

### 2. Deploy
Run the deployment at the subscription level. This creates the Resource Group and the VM in one step.

```bash
az deployment sub create \
  --name "DevWorkstationDeployment" \
  --location northeurope \
  --template-file main.bicep \
  --parameters sshPublicKey="$(ssh-keygen -y -f ~/.ssh/your-key-pair.pem)"
```

---

## 🔗 Connection Setup

Because we use a **DNS Label**, you never need to check the IP address.

1. Open `~/.ssh/config` on your Mac.
2. Add the following entry:

```text
Host azure-dev
    HostName ubuntu-dev-workstation.northeurope.cloudapp.azure.com
    User gabrielpedepera
    IdentityFile ~/.ssh/your-key-pair.pem
```

3. **In VS Code:** Press `Cmd + Shift + P`, select **Remote-SSH: Connect to Host...**, and choose `azure-dev`.

---

## ▶️ Resume Work

Once the infrastructure is deployed and your SSH config is in place, this is all you need each morning:

1. **Start the VM:**
   ```bash
   az vm start -g rg-remote-development -n ubuntu-remote-dev
   ```
2. **Connect from VS Code:** Press `Cmd + Shift + P` → **Remote-SSH: Connect to Host...** → select `azure-dev`.

> The VM auto-stops at 19:00 UTC daily, so no manual shutdown is needed.

---

## 💸 Cost Management
- **Start the VM:** `az vm start -g rg-remote-development -n ubuntu-remote-dev`
- **Stop the VM:** `az vm deallocate -g rg-remote-development -n ubuntu-remote-dev`
- **Auto-Shutdown:** The VM will stop automatically at 19:00 UTC daily.

---

## 🗑 Cleanup
To delete all resources and stop all charges:
```bash
az group delete --name rg-remote-development --yes --no-wait
```

---

## 📂 File Structure
- `main.bicep`: Subscription-level orchestrator.
- `dev-workstation.bicep`: Resource definitions (VM, Network, DNS).
