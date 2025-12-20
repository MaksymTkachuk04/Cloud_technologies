output "management_group_id" {
  value = azurerm_management_group.mg1.id
  description = "ID створеної групи керування"
}

output "helpdesk_group_id" {
  value = azuread_group.helpdesk.object_id
  description = "ID групи Help Desk"
}

output "custom_role_id" {
  value = azurerm_role_definition.custom_support_role.role_definition_id
  description = "ID кастомної ролі"
}

output "role_assignment_confirmation" {
  value = "Role 'Virtual Machine Contributor' assigned to group 'helpdesk' on scope 'az104-mg1'"
}