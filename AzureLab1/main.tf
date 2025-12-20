terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.40.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "azuread" {
}

variable "guest_email" {
  description = "makstkachuk04@gmail.com"
  type        = string
  default     = "makstkachuk04@gmail.com"
}

data "azuread_client_config" "current" {}

data "azuread_domains" "default" {
  only_initial = true
}

resource "random_password" "az104_user_pw" {
  length           = 16
  special          = true
  override_special = "!@#$%"
}

resource "azuread_user" "az104_user1" {
  user_principal_name = "az104-user1@${data.azuread_domains.default.domains.0.domain_name}"
  display_name        = "az104-user1"
  mail_nickname       = "az104-user1"
  password            = random_password.az104_user_pw.result
  force_password_change = true
  account_enabled     = true

  job_title      = "IT Lab Administrator"
  department     = "IT"
  usage_location = "US"
}

resource "azuread_invitation" "guest_user" {
  user_email_address = var.guest_email
  redirect_url       = "https://portal.azure.com"

  message {
    body = "Welcome to Azure and our group project"
  }
}

resource "azuread_group" "it_lab_admins" {
  display_name     = "IT Lab Administrators"
  description      = "Administrators that manage the IT lab"
  security_enabled = true
  mail_enabled     = false
  assignable_to_role = false
  owners = [data.azuread_client_config.current.object_id]
}

resource "azuread_group_member" "internal_user_member" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_user.az104_user1.object_id
}

resource "azuread_group_member" "guest_user_member" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = azuread_invitation.guest_user.user_id
  depends_on       = [azuread_invitation.guest_user]
}

resource "azuread_group_member" "admin_member" {
  group_object_id  = azuread_group.it_lab_admins.object_id
  member_object_id = data.azuread_client_config.current.object_id
}