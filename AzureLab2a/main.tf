terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0.0"
    }
  }
}

provider "azurerm" {
  features {}
}

provider "azuread" {}

data "azurerm_subscription" "current" {}
data "azuread_client_config" "current" {}

resource "azurerm_management_group" "mg1" {
  name         = "az104-mg1"
  display_name = "az104-mg1"
}

resource "azuread_group" "helpdesk" {
  display_name     = "helpdesk"
  security_enabled = true
  mail_enabled     = false
  description      = "Help Desk group for role assignment lab"
  members = [data.azuread_client_config.current.object_id]
}

resource "azurerm_role_assignment" "vm_contributor_assignment" {
  scope                = azurerm_management_group.mg1.id
  role_definition_name = "Virtual Machine Contributor"
  principal_id         = azuread_group.helpdesk.object_id
}

resource "azurerm_role_definition" "custom_support_role" {
  name        = "Custom Support Request"
  scope       = azurerm_management_group.mg1.id
  description = "A custom contributor role for support requests."

  permissions {
    actions = [
      "Microsoft.Support/*"
    ]
    
    not_actions = [
      "Microsoft.Support/register/action"
    ]
  }

  assignable_scopes = [
    azurerm_management_group.mg1.id
  ]
}