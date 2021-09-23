# ACI Auto-Healing
 Experiment to use Azure Functions to reset backend pool of application gateway, which is based on Azure Container Instance.

 Azure Services used:
 1. Azure Application Gateway
 1. Azure Container Instances
 1. Azure Functions (Durable)
 1. Azure Logic App
 1. Azure Monitor

This repository is to capture source code, the full explanation can be found here: [Host Web App Using Azure Container Instances Inside Virtual Network with Auto Private IP Rotation](https://medium.com/marcus-tee-anytime/host-web-app-using-azure-container-instances-inside-virtual-network-with-auto-private-ip-rotation-59bf9d7e0e0b)

## Instruction to deploy this solution using bicep
1. Login to [Azure Cloud Shell](https://shell.azure.com)
2. Clone this repo
``` bash
git clone https://github.com/guangying94/aci-auto-healing.git
cd ./Bicep\ Deployment
```
3. Set your Azure subscription in Azure Cloud Shell
``` bash
az account set -s <Replace-With-Your-Subscription-Id>
```
4. Run the following command to execute this script
``` bash
az deployment sub create -l <Replace-With-Azure-Region> --template-file main.bicep
```
5. It will prompt paramters for input. Make sure you have service principal client ID and secret ready.
6. It will take about 10 minutes to complete deployment