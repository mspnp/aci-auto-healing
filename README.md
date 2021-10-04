# Azure Container Instances - Auto Healing using Azure Functions

 This repo demonstrates using Azure Functions to reset the backend pool of Application Gateway which is pointing to an Azure Container Instance.

 Azure Services used:

 1. Azure Application Gateway
 1. Azure Container Instances
 1. Azure Functions (Durable)
 1. Azure Logic App
 1. Azure Monitor

## Instruction to deploy this solution using bicep

1. Login to [Azure Cloud Shell](https://shell.azure.com)

1. Clone this repo

```bash
git clone https://github.com/mspnp/aci-auto-healing.git
cd ./Bicep\ Deployment
```

1. Set your Azure subscription in Azure Cloud Shell (if not already set)

```bash
az account set -s <Replace-With-Your-Subscription-Id>
```

1. Run the following command to execute this script

```bash
az deployment sub create -l <Replace-With-Azure-Region> --template-file main.bicep
```

1. It will prompt paramters for input. Make sure you have service principal client ID and secret ready.

1. It will take about 10 minutes to complete deployment

## Contributing

This project welcomes contributions and suggestions.

### Contribution requirements

Most contributions require you to agree to a Contributor License Agreement (CLA) declaring that you have the right to, and actually do, grant us the rights to use your contribution. For details, visit https://cla.opensource.microsoft.com.

When you submit a pull request, a CLA bot will automatically determine whether you need to provide a CLA and decorate the PR appropriately (e.g., status check, comment). Simply follow the instructions provided by the bot. You will only need to do this once across all repos using our CLA.

## Code of Conduct

This project has adopted the [Microsoft Open Source Code of Conduct](https://opensource.microsoft.com/codeofconduct/). For more information see the [Code of Conduct FAQ](https://opensource.microsoft.com/codeofconduct/faq/) or contact [opencode@microsoft.com](mailto:opencode@microsoft.com) with any additional questions or comments.
