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

resource "azurerm_resource_group" "rg4" {
  name     = "az104-rg4"
  location = "East US"
}

resource "azurerm_virtual_network" "core_vnet" {
  name                = "CoreServicesVnet"
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
  address_space       = ["10.20.0.0/16"]
}

resource "azurerm_subnet" "shared_subnet" {
  name                 = "SharedServicesSubnet"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.10.0/24"]
}

resource "azurerm_subnet" "db_subnet" {
  name                 = "DatabaseSubnet"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.core_vnet.name
  address_prefixes     = ["10.20.20.0/24"]
}

resource "azurerm_virtual_network" "mfg_vnet" {
  name                = "ManufacturingVnet"
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
  address_space       = ["10.30.0.0/16"]
}

resource "azurerm_subnet" "sensor1_subnet" {
  name                 = "SensorSubnet1"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.20.0/24"]
}

resource "azurerm_subnet" "sensor2_subnet" {
  name                 = "SensorSubnet2"
  resource_group_name  = azurerm_resource_group.rg4.name
  virtual_network_name = azurerm_virtual_network.mfg_vnet.name
  address_prefixes     = ["10.30.21.0/24"]
}

resource "azurerm_application_security_group" "asg_web" {
  name                = "asg-web"
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_network_security_group" "nsg_secure" {
  name                = "myNSGSecure"
  location            = azurerm_resource_group.rg4.location
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_network_security_rule" "allow_asg" {
  name                        = "AllowASG"
  priority                    = 100
  direction                   = "Inbound"
  access                      = "Allow"
  protocol                    = "Tcp"
  source_port_range           = "*"
  destination_port_ranges     = ["80", "443"]
  source_address_prefix       = null
  source_application_security_group_ids = [azurerm_application_security_group.asg_web.id]
  destination_address_prefix  = "*"
  resource_group_name         = azurerm_resource_group.rg4.name
  network_security_group_name = azurerm_network_security_group.nsg_secure.name
}

resource "azurerm_network_security_rule" "deny_internet" {
  name                        = "DenyInternetOutBound"
  priority                    = 4096
  direction                   = "Outbound"
  access                      = "Deny"
  protocol                    = "*"
  source_port_range           = "*"
  destination_port_range      = "*"
  source_address_prefix       = "*"
  destination_address_prefix  = "Internet"
  resource_group_name         = azurerm_resource_group.rg4.name
  network_security_group_name = azurerm_network_security_group.nsg_secure.name
}

resource "azurerm_subnet_network_security_group_association" "nsg_assoc" {
  subnet_id                 = azurerm_subnet.shared_subnet.id
  network_security_group_id = azurerm_network_security_group.nsg_secure.id
}

resource "azurerm_dns_zone" "public_dns" {
  name                = "contoso-lab2025.com"
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_dns_a_record" "www_record" {
  name                = "www"
  zone_name           = azurerm_dns_zone.public_dns.name
  resource_group_name = azurerm_resource_group.rg4.name
  ttl                 = 1
  records             = ["10.1.1.4"]
}

resource "azurerm_private_dns_zone" "private_dns" {
  name                = "private.contoso.com"
  resource_group_name = azurerm_resource_group.rg4.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "mfg_link" {
  name                  = "manufacturing-link"
  resource_group_name   = azurerm_resource_group.rg4.name
  private_dns_zone_name = azurerm_private_dns_zone.private_dns.name
  virtual_network_id    = azurerm_virtual_network.mfg_vnet.id
}

resource "azurerm_private_dns_a_record" "sensor_record" {
  name                = "sensorvm"
  zone_name           = azurerm_private_dns_zone.private_dns.name
  resource_group_name = azurerm_resource_group.rg4.name
  ttl                 = 1
  records             = ["10.1.1.4"]
}