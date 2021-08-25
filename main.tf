provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = "${var.prefix}-resources-group"
  location = var.location
}

resource "azurerm_virtual_network" "main" {
  name                = "${var.prefix}-network"
  address_space       = ["10.0.0.0/24", "10.0.1.0/27"]
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = {
    project = var.project_name
  }
}

resource "azurerm_subnet" "internal" {
  name                 = "internal"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.0.0/24"]
}

resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = ["10.0.1.0/27"]
}

resource "azurerm_public_ip" "bastion" {
  name                = "bastionPublicIp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    project = var.project_name
  }
}

resource "azurerm_bastion_host" "bastion" {
  name                = "${var.prefix}-bastion"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  ip_configuration {
    name                 = "configuration"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion.id
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_network_watcher" "example" {
  name                = "production-nwwatcher"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.project_name
  }
}

resource "azurerm_network_security_group" "main" {
  name                = "outbound-nsg"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  security_rule {
    name                         = "allow_traffic_inside_subnet"
    priority                     = 100
    direction                    = "Inbound"
    access                       = "Allow"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefixes      = azurerm_subnet.internal.address_prefixes
    destination_address_prefixes = azurerm_subnet.internal.address_prefixes
  }

  security_rule {
    name                         = "deny_access_from_internet"
    priority                     = 200
    direction                    = "Inbound"
    access                       = "Deny"
    protocol                     = "*"
    source_port_range            = "*"
    destination_port_range       = "*"
    source_address_prefix        = "Internet"
    destination_address_prefixes = azurerm_subnet.internal.address_prefixes
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_public_ip" "main" {
  name                = "mainPublicIp"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  allocation_method   = "Static"
  sku                 = "Standard"
  tags = {
    project = var.project_name
  }
}

resource "azurerm_network_interface" "main" {
  count = var.virtual_machines_count
  name                = "${var.prefix}-nic-${count.index+1}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  ip_configuration {
    name                          = "internal-IP-${count.index+1}"
    subnet_id                     = azurerm_subnet.internal.id
    private_ip_address_allocation = "Dynamic"
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_network_interface_security_group_association" "main" {
  count = var.virtual_machines_count
  network_interface_id      = azurerm_network_interface.main[count.index].id
  network_security_group_id = azurerm_network_security_group.main.id
}

resource "azurerm_lb" "main" {
  name                = "webAppLoadBalancer"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "PublicIPAddress"
    public_ip_address_id = azurerm_public_ip.main.id
  }

  tags = {
    project = var.project_name
  }
}

resource "azurerm_lb_backend_address_pool" "main" {
  name            = "webapp_backend_address_pool"
  loadbalancer_id = azurerm_lb.main.id
}

resource "azurerm_network_interface_backend_address_pool_association" "main" {
  count = var.virtual_machines_count
  network_interface_id    = azurerm_network_interface.main[count.index].id
  ip_configuration_name   = "internal-IP-${count.index+1}"
  backend_address_pool_id = azurerm_lb_backend_address_pool.main.id
}

resource "azurerm_lb_probe" "http_probe" {
  resource_group_name = azurerm_resource_group.main.name
  loadbalancer_id     = azurerm_lb.main.id
  name                = "http-${var.prefix}-probe"
  port                = 80
  protocol = "Http"
  request_path = "/"
  interval_in_seconds = 15
  number_of_probes = 2
}

resource "azurerm_lb_rule" "example" {
  resource_group_name            = azurerm_resource_group.main.name
  loadbalancer_id                = azurerm_lb.main.id
  name                           = "baseHttpRule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "PublicIPAddress"
  probe_id = azurerm_lb_probe.http_probe.id
}

data "azurerm_image" "webapp_image" {
  name                = "TestFlaskAppServerImage"
  resource_group_name = "packer-images-rg"
}

resource "azurerm_availability_set" "main" {
  name                = "${var.prefix}-availability-set"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = {
    project = var.project_name
  }
}

resource "azurerm_linux_virtual_machine" "main" {
  count = var.virtual_machines_count
  name                            = "${var.prefix}-vm-${count.index+1}"
  resource_group_name             = azurerm_resource_group.main.name
  location                        = azurerm_resource_group.main.location
  size                            = "Standard_DS1_v2"
  admin_username                  = var.username
  admin_password                  = var.password
  disable_password_authentication = false
  network_interface_ids = [
    azurerm_network_interface.main[count.index].id,
  ]

  availability_set_id = azurerm_availability_set.main.id

  source_image_id = data.azurerm_image.webapp_image.id

  os_disk {
    storage_account_type = "Standard_LRS"
    caching              = "ReadWrite"
  }

  tags = {
    project = var.project_name
  }
}
