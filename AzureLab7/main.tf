terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    random = {
      source = "hashicorp/random"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "rg7" {
  name     = "az104-rg7"
  location = "West Europe"
}

resource "random_string" "unique" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_storage_account" "sa" {
  name                     = "az104sa${random_string.unique.result}"
  resource_group_name      = azurerm_resource_group.rg7.name
  location                 = azurerm_resource_group.rg7.location
  account_tier             = "Standard"
  account_replication_type = "GRS" # Geo-Redundant Storage
  min_tls_version          = "TLS1_2"

  public_network_access_enabled = true
}

resource "azurerm_storage_container" "data" {
  name                  = "data"
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = "private"
}

resource "azurerm_storage_management_policy" "lifecycle" {
  storage_account_id = azurerm_storage_account.sa.id

  rule {
    name    = "Movetocool"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["data/"]
    }
    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than = 30
      }
    }
  }
}

resource "azurerm_storage_share" "share" {
  name                 = "share1"
  storage_account_name = azurerm_storage_account.sa.name
  quota                = 5
}

resource "azurerm_virtual_network" "vnet" {
  name                = "vnet1"
  location            = azurerm_resource_group.rg7.location
  resource_group_name = azurerm_resource_group.rg7.name
  address_space       = ["10.70.0.0/16"]
}

resource "azurerm_subnet" "subnet" {
  name                 = "default"
  resource_group_name  = azurerm_resource_group.rg7.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.70.0.0/24"]

  service_endpoints    = ["Microsoft.Storage"] 
}