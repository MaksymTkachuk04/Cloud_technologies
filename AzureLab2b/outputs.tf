output "resource_group_name" {
  value       = azurerm_resource_group.rg2.name
  description = "Ім'я створеної групи ресурсів"
}

output "storage_account_name" {
  value       = azurerm_storage_account.lab_storage.name
  description = "Ім'я створеного стореджа (для перевірки тегів)"
}

output "policy_assignment_id" {
  value       = azurerm_resource_group_policy_assignment.inherit_cost_center.id
  description = "ID призначеної політики"
}

output "lock_status" {
  value       = "Resource Group '${azurerm_resource_group.rg2.name}' is now LOCKED (CanNotDelete)."
  description = "Статус блокування"
}