using System;
using System.Collections.Generic;
using System.Net.Http;
using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.Azure.WebJobs.Host;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.Management.ContainerInstance.Fluent;
using Microsoft.Azure.Management.ContainerInstance.Fluent.Models;
using Microsoft.Azure.Management.Fluent;
using Microsoft.Azure.Management.ResourceManager.Fluent;
using Microsoft.Azure.Management.Network.Fluent;
using System.Threading;
using System.Linq;
using Azure.Identity;

namespace aci_healing_durable
{
    public static class aci_healing_durable
    {
        [FunctionName("aci_healing_durable")]
        public static async Task<List<string>> RunOrchestrator(
            [OrchestrationTrigger] IDurableOrchestrationContext context)
        {
            List<string> goodACI = await context.CallActivityAsync<List<string>>("process_aci", "run");
            return goodACI;
        }

        [FunctionName("process_aci")]
        public static async Task<List<string>> ProcessACI([ActivityTrigger] string input, ILogger log)
        {
            //Information for service principal
            string clientId = Environment.GetEnvironmentVariable("SP_CLIENT_ID");
            string clientSecret = Environment.GetEnvironmentVariable("SP_CLIENT_SECRET");
            string tenantId = Environment.GetEnvironmentVariable("TENANT_ID");
            string subId = Environment.GetEnvironmentVariable("SUBS_ID");

            //Other variables
            string rgName = Environment.GetEnvironmentVariable("RG_NAME");
            string appGWName = Environment.GetEnvironmentVariable("APPGW_NAME");

            //Authenticate with Azure
            var credentials = SdkContext.AzureCredentialsFactory.FromServicePrincipal(clientId, clientSecret, tenantId, AzureEnvironment.AzureGlobalCloud);
            var azure = Microsoft.Azure.Management.Fluent.Azure.Configure().Authenticate(credentials).WithSubscription(subId);

            //Get list of container group from RG
            

            //Create a list to capture list of healthy IP Address
            List<string> goodACI = new List<string>();

            //Loop to check container group
            IEnumerable<IContainerGroup> containerGroups = azure.ContainerGroups.ListByResourceGroup(rgName);
            foreach (IContainerGroup containerGroup in containerGroups)
            {
                log.LogInformation($"Checking {containerGroup.Name}...");
                if (containerGroup.State == "Running")
                {
                    goodACI.Add(containerGroup.IPAddress);
                    log.LogInformation($"{containerGroup.Name} at {containerGroup.IPAddress} is running.");
                }
                else
                {
                    //Ensure ACI is completely deleted to avoid naming conflict
                    bool cgIsDeleted = false;

                    while (!cgIsDeleted)
                    {
                        cgIsDeleted = DeleteACIAsync(azure, containerGroup, rgName, containerGroup.Name, log);
                    }

                    //Buffer
                    Thread.Sleep(1000);

                    //create new ACI using same configuration of bad ACI
                    string _result = CreateACIAsync(azure, containerGroup, rgName, log);
                    goodACI.Add(_result);
                }
            }

            //Update AppGW backend pool
            UpdateAppGW(azure, rgName, appGWName, goodACI, log);

            //return list of IP for AppGW new backend pool
            return goodACI;
        }

        public static bool DeleteACIAsync(IAzure azure, IContainerGroup containerGroup, string rgName, string cgName, ILogger log)
        {
            azure.ContainerGroups.DeleteById(containerGroup.Id);

            IContainerGroup _containerGroup = containerGroup;

            while (_containerGroup != null)
            {
                try
                {
                    _containerGroup = azure.ContainerGroups.GetByResourceGroup(rgName, cgName);
                    SdkContext.DelayProvider.Delay(1000);
                }
                catch (OperationErrorException e)
                {
                    log.LogInformation(e.Message);
                    _containerGroup = null;
                }
                Thread.Sleep(1000);
            }
            log.LogInformation($"{containerGroup.Name} is deleted...");
            return true;
        }

        public static string CreateACIAsync(IAzure azure, IContainerGroup containerGroup, string rgName, ILogger log)
        {
            //Variable for Azure Container Registry
            string acrServer = Environment.GetEnvironmentVariable("ACR_SERVER_NAME");
            string acrName = Environment.GetEnvironmentVariable("ACR_USERNAME");
            string acrPw = Environment.GetEnvironmentVariable("ACR_PW");

            //Additional variables
            string subId = Environment.GetEnvironmentVariable("SUBS_ID");
            string networkProfile = Environment.GetEnvironmentVariable("NETWORK_PROFILE_NAME");

            //Replicate existing ACI configuration
            string aciImage = containerGroup.Inner.Containers[0].Image;
            double aciCPU = containerGroup.Inner.Containers[0].Resources.Requests.Cpu;
            double aciRAM = containerGroup.Inner.Containers[0].Resources.Requests.MemoryInGB;
            string aciRegion = containerGroup.RegionName;

            //To be updated if there are multiple values
            int aciPort = containerGroup.Inner.Containers[0].Ports[0].Port;
            var aciEnvName = containerGroup.Inner.Containers[0].EnvironmentVariables[0].Name;
            var aciEnvValue = containerGroup.Inner.Containers[0].EnvironmentVariables[0].Value;

            //Create new ACI
            azure.ContainerGroups.Define(containerGroup.Name)
                          .WithRegion(aciRegion)
                          .WithExistingResourceGroup(rgName)
                          .WithLinux()
                          .WithPrivateImageRegistry(acrServer, acrName, acrPw)
                          .WithoutVolume()
                          .DefineContainerInstance(containerGroup.Name)
                          .WithImage(aciImage)
                          .WithInternalTcpPort(aciPort)
                          .WithExternalTcpPort(1000) // ACI in VNET doesnt requires External Port, but I guess it's a bug in SDK that requires this variable. The port number shouldnt have any impact//
                          .WithMemorySizeInGB(aciRAM)
                          .WithCpuCoreCount(aciCPU)
                          .WithEnvironmentVariable(aciEnvName, aciEnvValue)
                          .Attach()
                          .WithRestartPolicy(ContainerGroupRestartPolicy.Always)
                          .WithNetworkProfileId(subId, rgName, networkProfile)
                          .Create();

            log.LogInformation("new ACI is created");
            IContainerGroup _containerGroup = azure.ContainerGroups.GetByResourceGroup(rgName,containerGroup.Name);

            //Check ACI status
            while (_containerGroup.State != "Running")
            {
                log.LogInformation("Validating...");
                Thread.Sleep(750);
            }

            log.LogInformation($"{_containerGroup.Name} is created at {_containerGroup.IPAddress}...");
            return _containerGroup.IPAddress;
        }

        public static void UpdateAppGW(IAzure azure, string rgName, string appgwName, List<string> goodIP, ILogger log)
        {
            //AppGW Backend Pool Name
            string bepool = Environment.GetEnvironmentVariable("APPGW_BEPOOL_NAME");
            //AppGW Listener Name
            string listener = Environment.GetEnvironmentVariable("APPGW_LISTENER_NAME");
            //APPGW HTTP Setting Name
            string http_setting = Environment.GetEnvironmentVariable("APPGW_HTTPSETTING_NAME");

            //Get AppGW details
            IApplicationGateway appgw = azure.ApplicationGateways.GetByResourceGroup(rgName, appgwName);

            appgw.Backends.TryGetValue(bepool, out IApplicationGatewayBackend currentBE);

            //Get current backend pool IP
            List<string> currentIP = new List<string>();

            foreach (var ip in currentBE.Inner.BackendAddresses)
            {
                currentIP.Add(ip.IpAddress);
            }

            //Filter out IP to add, or IP to remove
            IEnumerable<string> ipToRemove = currentIP.Except(goodIP);
            IEnumerable<string> ipToAdd = goodIP.Except(currentIP);

            //Remove IP
            if (ipToRemove.Any())
            {
                foreach (string ip in ipToRemove)
                {
                    appgw.Update().WithoutBackendIPAddress(ip).Apply();
                    log.LogInformation($"{ip} is removed...");
                }
            }

            //Add new IP
            if (ipToAdd.Any())
            {
                List<string> _ipList = new List<string>();
                foreach (string ip in ipToAdd)
                {
                    _ipList.Add(ip);
                }

                appgw.Update().DefineRequestRoutingRule(listener).FromListener(listener)
                    .ToBackendHttpConfiguration(http_setting).ToBackendIPAddresses(_ipList.ToArray()).Attach().Apply();

                log.LogInformation($"{_ipList.Count} ip is added to backend pool");
            }

            log.LogInformation("completed backend pool updates...");
        }


        [FunctionName("aci_healing_durable_HttpStart")]
        public static async Task<HttpResponseMessage> HttpStart(
            [HttpTrigger(AuthorizationLevel.Anonymous, "get", "post")] HttpRequestMessage req,
            [DurableClient] IDurableOrchestrationClient starter,
            ILogger log)
        {
            string instanceId = await starter.StartNewAsync("aci_healing_durable", null);

            log.LogInformation($"Started orchestration with ID = '{instanceId}'.");

            return starter.CreateCheckStatusResponse(req, instanceId);
        }
    }
}
