# Azure Infrastructure Operations Project: Deploying a scalable IaaS web server in Azure

### Introduction
For this project, you will build infrastructure and deploy a customizable, scalable web server in Azure.

### Getting Started
1. Make sure you want and can use Microsoft Azure Cloud
2. Make sure you are familiar with using command line tools - pick up your preffered command-line shell to work with
1. Clone this repository

### Dependencies
1. Create an [Azure Account](https://portal.azure.com) 
2. Install the [Azure command line interface](https://docs.microsoft.com/en-us/cli/azure/install-azure-cli?view=azure-cli-latest)
3. Install [Packer](https://www.packer.io/downloads)
4. Install [Terraform](https://www.terraform.io/downloads.html)

### Instructions
1. Login to azure using command

az login

If you have more than 1 subscription, you can set default subscription using command

az account set --subscription <TARGET_SUBSCRIPTION>

2. Navigate to the folder you have files cloned from this repository

3. If needed, fill up variables in file server-service.json (in case you want to use client credentials or specify subscription id). Build packer image using command:

packer build server-service.json

This creates image with name "TestFlaskAppServerImage" using resource group "packer-images-rg"
Image is based on Linux Ubuntu OS and uses Python flask webserver to serve simple "Hello world" webpage
Names of the image and resource group are used in further steps, so make sure you are using right identifiers if you want to customize this project.

To delete created image in your subscription, use Azure Portal or use command:

az image delete -g packer-images-rg -n TestFlaskAppServerImage

4. Build a terraform plan (based on files main.tf and vars.tf) file using command

terraform plan -out solution.plan

Using this command, you will be asked to enter your variables defined in vars.tf file like username and password for virtual machines, number of virtual machines or your Azure subscription and Azure Region where you want to deploy infrastructure configured in terraform files.

You can customize variables using file vars.tf
This file includes variables with default values you can change like:
prefix - prefix for name (used for all resources), default "website"
location - the Azure Region in which all resources in this example should be created, default West Europe
username - user Name for virtual machine, default "udacity"
password - password for virtual machine user, no default set
project_name - project name to be used in resources tags, default "udacity-web-app"
virtual_machines_count - number of virtual machines under Load Balancer, default 2 - should be between 2 and 5

Target infrastructure is defined in file main.tf

5. Apply plan to create real infrastructure in Azure - use command

terraform apply solution.plan

This will take a while to deploy in Azure

6. After applying previous step, go to Azure portal or use command below:

terraform show

Check public IP (there is single public IP configured) - that will be entry point for the target application, using this IP you should be able to check if application is working - it should show simple web page with "Hello World" on it.
If you see nothing, webserver can be turned off on target virtual machine - you can search in Azure Portal for virtual machines, connect to them using bastion and turn on simple webserver using commands:

echo 'Hello World!' > index.html
sudo nohup busybox httpd -f -p 80 &

Check again if site is working using public IP.

7. [OPTIONAL] At the end, if you want to destroy created infrastructure to not longer use it or pay for it, use command:

terraform destroy

### Output
Output of the command terraform show (step 6) should be similar to this (assigned IPs and resources identifiers can be different)
I configured 3 virtual machines using configuration variables

resource "azurerm_availability_set" "main" {
    id                           = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/availabilitySets/webapp-availability-set"
    location                     = "westeurope"
    managed                      = true
    name                         = "webapp-availability-set"
    platform_fault_domain_count  = 3
    platform_update_domain_count = 5
    resource_group_name          = "webapp-resources-group"
    tags                         = {
        "app" = "webapp"
    }
}

# azurerm_bastion_host.bastion:
resource "azurerm_bastion_host" "bastion" {
    dns_name            = "bst-ebbc38c5-23ba-4a67-9339-f33ea30776a9.bastion.azure.com"
    id                  = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/bastionHosts/webapp-bastion"
    location            = "westeurope"
    name                = "webapp-bastion"
    resource_group_name = "webapp-resources-group"
    tags                = {
        "app" = "webapp"
    }

    ip_configuration {
        name                 = "configuration"
        public_ip_address_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/publicIPAddresses/bastionPublicIp"
        subnet_id            = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network/subnets/AzureBastionSubnet"
    }
}

# azurerm_lb.main:
resource "azurerm_lb" "main" {
    id                   = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer"
    location             = "westeurope"
    name                 = "webAppLoadBalancer"
    private_ip_addresses = []
    resource_group_name  = "webapp-resources-group"
    sku                  = "Standard"
    tags                 = {
        "app" = "webapp"
    }

    frontend_ip_configuration {
        id                            = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/frontendIPConfigurations/PublicIPAddress"
        inbound_nat_rules             = []
        load_balancer_rules           = []
        name                          = "PublicIPAddress"
        outbound_rules                = []
        private_ip_address_allocation = "Dynamic"
        public_ip_address_id          = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/publicIPAddresses/mainPublicIp"
    }
}

# azurerm_lb_backend_address_pool.main:
resource "azurerm_lb_backend_address_pool" "main" {
    backend_ip_configurations = []
    id                        = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    load_balancing_rules      = []
    loadbalancer_id           = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer"
    name                      = "webapp_backend_address_pool"
    outbound_rules            = []
    resource_group_name       = "webapp-resources-group"
}

# azurerm_lb_probe.http_probe:
resource "azurerm_lb_probe" "http_probe" {
    id                  = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/probes/http-webapp-probe"
    interval_in_seconds = 15
    load_balancer_rules = []
    loadbalancer_id     = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer"
    name                = "http-webapp-probe"
    number_of_probes    = 2
    port                = 80
    protocol            = "Http"
    request_path        = "/"
    resource_group_name = "webapp-resources-group"
}

# azurerm_lb_rule.example:
resource "azurerm_lb_rule" "example" {
    backend_port                   = 80
    disable_outbound_snat          = false
    enable_floating_ip             = false
    enable_tcp_reset               = false
    frontend_ip_configuration_id   = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/frontendIPConfigurations/PublicIPAddress"
    frontend_ip_configuration_name = "PublicIPAddress"
    frontend_port                  = 80
    id                             = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/loadBalancingRules/baseHttpRule"
    idle_timeout_in_minutes        = 4
    load_distribution              = "Default"
    loadbalancer_id                = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer"
    name                           = "baseHttpRule"
    probe_id                       = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/probes/http-webapp-probe"
    protocol                       = "Tcp"
    resource_group_name            = "webapp-resources-group"
}

# azurerm_linux_virtual_machine.main[1]:
resource "azurerm_linux_virtual_machine" "main" {
    admin_password                  = (sensitive value)
    admin_username                  = "Udacity"
    allow_extension_operations      = true
    availability_set_id             = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/availabilitySets/WEBAPP-AVAILABILITY-SET"
    computer_name                   = "webapp-vm-2"
    disable_password_authentication = false
    encryption_at_host_enabled      = false
    extensions_time_budget          = "PT1H30M"
    id                              = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/virtualMachines/webapp-vm-2"
    location                        = "westeurope"
    max_bid_price                   = -1
    name                            = "webapp-vm-2"
    network_interface_ids           = [
        "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-2",
    ]
    platform_fault_domain           = -1
    priority                        = "Regular"
    private_ip_address              = "10.0.0.5"
    private_ip_addresses            = [
        "10.0.0.5",
    ]
    provision_vm_agent              = true
    public_ip_addresses             = []
    resource_group_name             = "webapp-resources-group"
    size                            = "Standard_DS1_v2"
    source_image_id                 = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/packer-images-rg/providers/Microsoft.Compute/images/TestFlaskAppServerImage"
    tags                            = {
        "app" = "webapp"
    }
    virtual_machine_id              = "8d15fcae-1df3-44dd-aa3e-997de30e16e6"

    os_disk {
        caching                   = "ReadWrite"
        disk_size_gb              = 30
        name                      = "webapp-vm-2_disk1_cb826776469d472a83d02966dcdd0cb4"
        storage_account_type      = "Standard_LRS"
        write_accelerator_enabled = false
    }
}

# azurerm_linux_virtual_machine.main[2]:
resource "azurerm_linux_virtual_machine" "main" {
    admin_password                  = (sensitive value)
    admin_username                  = "Udacity"
    allow_extension_operations      = true
    availability_set_id             = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/availabilitySets/WEBAPP-AVAILABILITY-SET"
    computer_name                   = "webapp-vm-3"
    disable_password_authentication = false
    encryption_at_host_enabled      = false
    extensions_time_budget          = "PT1H30M"
    id                              = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/virtualMachines/webapp-vm-3"
    location                        = "westeurope"
    max_bid_price                   = -1
    name                            = "webapp-vm-3"
    network_interface_ids           = [
        "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-3",
    ]
    platform_fault_domain           = -1
    priority                        = "Regular"
    private_ip_address              = "10.0.0.4"
    private_ip_addresses            = [
        "10.0.0.4",
    ]
    provision_vm_agent              = true
    public_ip_addresses             = []
    resource_group_name             = "webapp-resources-group"
    size                            = "Standard_DS1_v2"
    source_image_id                 = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/packer-images-rg/providers/Microsoft.Compute/images/TestFlaskAppServerImage"
    tags                            = {
        "app" = "webapp"
    }
    virtual_machine_id              = "7985933b-0e95-45ac-a617-1db7d4e446f0"

    os_disk {
        caching                   = "ReadWrite"
        disk_size_gb              = 30
        name                      = "webapp-vm-3_disk1_de871c5d9c8f49d1ae3daceba16c4928"
        storage_account_type      = "Standard_LRS"
        write_accelerator_enabled = false
    }
}

# azurerm_linux_virtual_machine.main[0]:
resource "azurerm_linux_virtual_machine" "main" {
    admin_password                  = (sensitive value)
    admin_username                  = "Udacity"
    allow_extension_operations      = true
    availability_set_id             = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/availabilitySets/WEBAPP-AVAILABILITY-SET"
    computer_name                   = "webapp-vm-1"
    disable_password_authentication = false
    encryption_at_host_enabled      = false
    extensions_time_budget          = "PT1H30M"
    id                              = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Compute/virtualMachines/webapp-vm-1"
    location                        = "westeurope"
    max_bid_price                   = -1
    name                            = "webapp-vm-1"
    network_interface_ids           = [
        "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-1",
    ]
    platform_fault_domain           = -1
    priority                        = "Regular"
    private_ip_address              = "10.0.0.6"
    private_ip_addresses            = [
        "10.0.0.6",
    ]
    provision_vm_agent              = true
    public_ip_addresses             = []
    resource_group_name             = "webapp-resources-group"
    size                            = "Standard_DS1_v2"
    source_image_id                 = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/packer-images-rg/providers/Microsoft.Compute/images/TestFlaskAppServerImage"
    tags                            = {
        "app" = "webapp"
    }
    virtual_machine_id              = "4ff8be29-77e0-4623-be4e-86be9eabedf8"

    os_disk {
        caching                   = "ReadWrite"
        disk_size_gb              = 30
        name                      = "webapp-vm-1_disk1_df662b8020ae4326aa458a3043b04bd0"
        storage_account_type      = "Standard_LRS"
        write_accelerator_enabled = false
    }
}

# azurerm_network_interface.main[2]:
resource "azurerm_network_interface" "main" {
    applied_dns_servers           = []
    dns_servers                   = []
    enable_accelerated_networking = false
    enable_ip_forwarding          = false
    id                            = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-3"
    internal_domain_name_suffix   = "bsqk033y3odulfyuzjq4qhd4pb.ax.internal.cloudapp.net"
    location                      = "westeurope"
    name                          = "webapp-nic-3"
    private_ip_address            = "10.0.0.4"
    private_ip_addresses          = [
        "10.0.0.4",
    ]
    resource_group_name           = "webapp-resources-group"
    tags                          = {
        "app" = "webapp"
    }

    ip_configuration {
        name                          = "internal-IP-3"
        primary                       = true
        private_ip_address            = "10.0.0.4"
        private_ip_address_allocation = "Dynamic"
        private_ip_address_version    = "IPv4"
        subnet_id                     = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network/subnets/internal"
    }
}

# azurerm_network_interface.main[0]:
resource "azurerm_network_interface" "main" {
    applied_dns_servers           = []
    dns_servers                   = []
    enable_accelerated_networking = false
    enable_ip_forwarding          = false
    id                            = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-1"
    internal_domain_name_suffix   = "bsqk033y3odulfyuzjq4qhd4pb.ax.internal.cloudapp.net"
    location                      = "westeurope"
    name                          = "webapp-nic-1"
    private_ip_address            = "10.0.0.6"
    private_ip_addresses          = [
        "10.0.0.6",
    ]
    resource_group_name           = "webapp-resources-group"
    tags                          = {
        "app" = "webapp"
    }

    ip_configuration {
        name                          = "internal-IP-1"
        primary                       = true
        private_ip_address            = "10.0.0.6"
        private_ip_address_allocation = "Dynamic"
        private_ip_address_version    = "IPv4"
        subnet_id                     = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network/subnets/internal"
    }
}

# azurerm_network_interface.main[1]:
resource "azurerm_network_interface" "main" {
    applied_dns_servers           = []
    dns_servers                   = []
    enable_accelerated_networking = false
    enable_ip_forwarding          = false
    id                            = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-2"
    internal_domain_name_suffix   = "bsqk033y3odulfyuzjq4qhd4pb.ax.internal.cloudapp.net"
    location                      = "westeurope"
    name                          = "webapp-nic-2"
    private_ip_address            = "10.0.0.5"
    private_ip_addresses          = [
        "10.0.0.5",
    ]
    resource_group_name           = "webapp-resources-group"
    tags                          = {
        "app" = "webapp"
    }

    ip_configuration {
        name                          = "internal-IP-2"
        primary                       = true
        private_ip_address            = "10.0.0.5"
        private_ip_address_allocation = "Dynamic"
        private_ip_address_version    = "IPv4"
        subnet_id                     = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network/subnets/internal"
    }
}

# azurerm_network_interface_backend_address_pool_association.main[2]:
resource "azurerm_network_interface_backend_address_pool_association" "main" {
    backend_address_pool_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    id                      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-3/ipConfigurations/internal-IP-3|/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    ip_configuration_name   = "internal-IP-3"
    network_interface_id    = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-3"
}

# azurerm_network_interface_backend_address_pool_association.main[0]:
resource "azurerm_network_interface_backend_address_pool_association" "main" {
    backend_address_pool_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    id                      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-1/ipConfigurations/internal-IP-1|/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    ip_configuration_name   = "internal-IP-1"
    network_interface_id    = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-1"
}

# azurerm_network_interface_backend_address_pool_association.main[1]:
resource "azurerm_network_interface_backend_address_pool_association" "main" {
    backend_address_pool_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    id                      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-2/ipConfigurations/internal-IP-2|/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/loadBalancers/webAppLoadBalancer/backendAddressPools/webapp_backend_address_pool"
    ip_configuration_name   = "internal-IP-2"
    network_interface_id    = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-2"
}

# azurerm_network_interface_security_group_association.main[2]:
resource "azurerm_network_interface_security_group_association" "main" {
    id                        = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-3|/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
    network_interface_id      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-3"
    network_security_group_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
}

# azurerm_network_interface_security_group_association.main[0]:
resource "azurerm_network_interface_security_group_association" "main" {
    id                        = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-1|/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
    network_interface_id      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-1"
    network_security_group_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
}

# azurerm_network_interface_security_group_association.main[1]:
resource "azurerm_network_interface_security_group_association" "main" {
    id                        = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-2|/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
    network_interface_id      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkInterfaces/webapp-nic-2"
    network_security_group_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
}

# azurerm_network_security_group.main:
resource "azurerm_network_security_group" "main" {
    id                  = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/networkSecurityGroups/outbound-nsg"
    location            = "westeurope"
    name                = "outbound-nsg"
    resource_group_name = "webapp-resources-group"
    security_rule       = [
        {
            access                                     = "Allow"
            description                                = ""
            destination_address_prefix                 = ""
            destination_address_prefixes               = [
                "10.0.0.0/24",
            ]
            destination_application_security_group_ids = []
            destination_port_range                     = "*"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "allow_traffic_inside_subnet"
            priority                                   = 100
            protocol                                   = "*"
            source_address_prefix                      = ""
            source_address_prefixes                    = [
                "10.0.0.0/24",
            ]
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
        {
            access                                     = "Deny"
            description                                = ""
            destination_address_prefix                 = ""
            destination_address_prefixes               = [
                "10.0.0.0/24",
            ]
            destination_application_security_group_ids = []
            destination_port_range                     = "*"
            destination_port_ranges                    = []
            direction                                  = "Inbound"
            name                                       = "deny_access_from_internet"
            priority                                   = 200
            protocol                                   = "*"
            source_address_prefix                      = "Internet"
            source_address_prefixes                    = []
            source_application_security_group_ids      = []
            source_port_range                          = "*"
            source_port_ranges                         = []
        },
    ]
    tags                = {
        "app" = "webapp"
    }
}

# azurerm_public_ip.bastion:
resource "azurerm_public_ip" "bastion" {
    allocation_method       = "Static"
    id                      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/publicIPAddresses/bastionPublicIp"
    idle_timeout_in_minutes = 4
    ip_address              = "20.93.237.13"
    ip_version              = "IPv4"
    location                = "westeurope"
    name                    = "bastionPublicIp"
    resource_group_name     = "webapp-resources-group"
    sku                     = "Standard"
    tags                    = {
        "app" = "webapp"
    }
}

# azurerm_public_ip.main:
resource "azurerm_public_ip" "main" {
    allocation_method       = "Static"
    id                      = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/publicIPAddresses/mainPublicIp"
    idle_timeout_in_minutes = 4
    ip_address              = "20.82.42.240"
    ip_version              = "IPv4"
    location                = "westeurope"
    name                    = "mainPublicIp"
    resource_group_name     = "webapp-resources-group"
    sku                     = "Standard"
    tags                    = {
        "app" = "webapp"
    }
}

# azurerm_resource_group.main:
resource "azurerm_resource_group" "main" {
    id       = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group"
    location = "westeurope"
    name     = "webapp-resources-group"
    tags     = {}
}

# azurerm_subnet.bastion_subnet:
resource "azurerm_subnet" "bastion_subnet" {
    address_prefix                                 = "10.0.1.0/27"
    address_prefixes                               = [
        "10.0.1.0/27",
    ]
    enforce_private_link_endpoint_network_policies = false
    enforce_private_link_service_network_policies  = false
    id                                             = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network/subnets/AzureBastionSubnet"
    name                                           = "AzureBastionSubnet"
    resource_group_name                            = "webapp-resources-group"
    virtual_network_name                           = "webapp-network"
}

# azurerm_subnet.internal:
resource "azurerm_subnet" "internal" {
    address_prefix                                 = "10.0.0.0/24"
    address_prefixes                               = [
        "10.0.0.0/24",
    ]
    enforce_private_link_endpoint_network_policies = false
    enforce_private_link_service_network_policies  = false
    id                                             = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network/subnets/internal"
    name                                           = "internal"
    resource_group_name                            = "webapp-resources-group"
    virtual_network_name                           = "webapp-network"
}

# azurerm_virtual_network.main:
resource "azurerm_virtual_network" "main" {
    address_space         = [
        "10.0.0.0/24",
        "10.0.1.0/27",
    ]
    guid                  = "77ada00c-ebb8-4587-9714-ca61e81c7e79"
    id                    = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/webapp-resources-group/providers/Microsoft.Network/virtualNetworks/webapp-network"
    location              = "westeurope"
    name                  = "webapp-network"
    resource_group_name   = "webapp-resources-group"
    subnet                = []
    tags                  = {
        "app" = "webapp"
    }
    vm_protection_enabled = false
}

# data.azurerm_image.webapp_image:
data "azurerm_image" "webapp_image" {
    data_disk           = []
    id                  = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/packer-images-rg/providers/Microsoft.Compute/images/TestFlaskAppServerImage"
    location            = "westeurope"
    name                = "TestFlaskAppServerImage"
    os_disk             = [
        {
            blob_uri        = ""
            caching         = "ReadWrite"
            managed_disk_id = "/subscriptions/27102d45-7168-47f6-b121-0ae8c0b1c1d8/resourceGroups/pkr-Resource-Group-wc14hh2r19/providers/Microsoft.Compute/disks/pkroswc14hh2r19"
            os_state        = "Generalized"
            os_type         = "Linux"
            size_gb         = 30
        },
    ]
    resource_group_name = "packer-images-rg"
    sort_descending     = false
    tags                = {
        "app" = "webserver_hello_world"
    }
    zone_resilient      = false
}
