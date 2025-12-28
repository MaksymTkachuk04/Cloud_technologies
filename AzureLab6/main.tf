terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg6" {
  name     = "az104-rg6"
  location = "West Europe"
}

resource "azurerm_virtual_network" "vnet" {
  name                = "az104-06-vnet1"
  address_space       = ["10.60.0.0/16"]
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name
}

resource "azurerm_subnet" "subnet_backend" {
  name                 = "subnet0" # Як у Task 1
  resource_group_name  = azurerm_resource_group.rg6.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.0.0/24"]
}

resource "azurerm_subnet" "subnet_appgw" {
  name                 = "subnet-appgw"
  resource_group_name  = azurerm_resource_group.rg6.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.60.3.224/27"]
}

resource "azurerm_public_ip" "lb_pip" {
  name                = "az104-lbpip"
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_lb" "lb" {
  name                = "az104-lb"
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name
  sku                 = "Standard"

  frontend_ip_configuration {
    name                 = "az104-fe"
    public_ip_address_id = azurerm_public_ip.lb_pip.id
  }
}

resource "azurerm_lb_backend_address_pool" "lb_bepool" {
  loadbalancer_id = azurerm_lb.lb.id
  name            = "az104-be"
}

resource "azurerm_lb_probe" "lb_probe" {
  loadbalancer_id     = azurerm_lb.lb.id
  name                = "az104-hp"
  port                = 80
  protocol            = "Tcp"
  interval_in_seconds = 5
  number_of_probes    = 2
}

resource "azurerm_lb_rule" "lb_rule" {
  loadbalancer_id                = azurerm_lb.lb.id
  name                           = "az104-lbrule"
  protocol                       = "Tcp"
  frontend_port                  = 80
  backend_port                   = 80
  frontend_ip_configuration_name = "az104-fe"
  backend_address_pool_ids       = [azurerm_lb_backend_address_pool.lb_bepool.id]
  probe_id                       = azurerm_lb_probe.lb_probe.id
}

resource "azurerm_public_ip" "appgw_pip" {
  name                = "az104-gwpip"
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "az104-appgw"
  resource_group_name = azurerm_resource_group.rg6.name
  location            = azurerm_resource_group.rg6.location

  sku {
    name     = "Standard_v2" #
    tier     = "Standard_v2"
    capacity = 2
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20170401S"
  }

  gateway_ip_configuration {
    name      = "my-gateway-ip-configuration"
    subnet_id = azurerm_subnet.subnet_appgw.id
  }

  frontend_port {
    name = "port_80"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appGwPublicFrontendIp"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  backend_address_pool {
    name = "az104-appgwbe"
  }
  
  backend_address_pool {
    name = "az104-imagebe"
  }

  backend_address_pool {
    name = "az104-videobe"
  }

  backend_http_settings {
    name                  = "httpSettings"
    cookie_based_affinity = "Disabled"
    path                  = "/"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 60
  }

  http_listener {
    name                           = "az104-listener"
    frontend_ip_configuration_name = "appGwPublicFrontendIp"
    frontend_port_name             = "port_80"
    protocol                       = "Http"
  }

  url_path_map {
    name                               = "urlPathMap"
    default_backend_address_pool_name  = "az104-appgwbe"
    default_backend_http_settings_name = "httpSettings"

    path_rule {
      name                       = "images"
      paths                      = ["/image/*"]
      backend_address_pool_name  = "az104-imagebe"
      backend_http_settings_name = "httpSettings"
    }

    path_rule {
      name                       = "videos"
      paths                      = ["/video/*"]
      backend_address_pool_name  = "az104-videobe"
      backend_http_settings_name = "httpSettings"
    }
  }

  request_routing_rule {
    name               = "az104-gwrule"
    rule_type          = "PathBasedRouting"
    http_listener_name = "az104-listener"
    url_path_map_name  = "urlPathMap"
    priority           = 10
  }
}

resource "azurerm_network_interface" "nic1" {
  name                = "az104-06-vm1-nic"
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic1_lb" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_bepool.id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic1_appgw_general" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id # az104-appgwbe
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic1_appgw_images" {
  network_interface_id    = azurerm_network_interface.nic1.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgw.backend_address_pool)[1].id # az104-imagebe
}

resource "azurerm_windows_virtual_machine" "vm1" {
  name                = "az104-06-vm1"
  resource_group_name = azurerm_resource_group.rg6.name
  location            = azurerm_resource_group.rg6.location
  size                = "Standard_D2s_v3"
  admin_username      = "localadmin"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.nic1.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm1_iis" {
  name                 = "install-iis-images"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm1.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server; New-Item -Path C:\\inetpub\\wwwroot\\image -ItemType Directory -Force; Set-Content -Path C:\\inetpub\\wwwroot\\image\\test.htm -Value 'This is the IMAGE server (VM1)'\""
    }
  SETTINGS
}

resource "azurerm_network_interface" "nic2" {
  name                = "az104-06-vm2-nic"
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_backend.id
    private_ip_address_allocation = "Dynamic"
  }
}

resource "azurerm_network_interface_backend_address_pool_association" "nic2_lb" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = azurerm_lb_backend_address_pool.lb_bepool.id
}

resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic2_appgw_general" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgw.backend_address_pool)[0].id 
}
resource "azurerm_network_interface_application_gateway_backend_address_pool_association" "nic2_appgw_videos" {
  network_interface_id    = azurerm_network_interface.nic2.id
  ip_configuration_name   = "ipconfig1"
  backend_address_pool_id = tolist(azurerm_application_gateway.appgw.backend_address_pool)[2].id # az104-videobe
}

resource "azurerm_windows_virtual_machine" "vm2" {
  name                = "az104-06-vm2"
  resource_group_name = azurerm_resource_group.rg6.name
  location            = azurerm_resource_group.rg6.location
  size                = "Standard_D2s_v3"
  admin_username      = "localadmin"
  admin_password      = "P@ssw0rd1234!"
  network_interface_ids = [azurerm_network_interface.nic2.id]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }
  source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = "2019-Datacenter"
    version   = "latest"
  }
}

resource "azurerm_virtual_machine_extension" "vm2_iis" {
  name                 = "install-iis-videos"
  virtual_machine_id   = azurerm_windows_virtual_machine.vm2.id
  publisher            = "Microsoft.Compute"
  type                 = "CustomScriptExtension"
  type_handler_version = "1.9"

  protected_settings = <<SETTINGS
    {
      "commandToExecute": "powershell -ExecutionPolicy Unrestricted -Command \"Install-WindowsFeature -Name Web-Server; New-Item -Path C:\\inetpub\\wwwroot\\video -ItemType Directory -Force; Set-Content -Path C:\\inetpub\\wwwroot\\video\\test.htm -Value 'This is the VIDEO server (VM2)'\""
    }
  SETTINGS
}

resource "azurerm_network_security_group" "nsg_web" {
  name                = "az104-06-nsg-web"
  location            = azurerm_resource_group.rg6.location
  resource_group_name = azurerm_resource_group.rg6.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_backend.id
  network_security_group_id = azurerm_network_security_group.nsg_web.id
}