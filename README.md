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

## Contributing

This project welcomes contributions and suggestions.

### Contribution requirements

Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
