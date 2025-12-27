output "resource_group" {
  value = azurerm_resource_group.rg3.name
}

output "created_disks" {
  value = [
    azurerm_managed_disk.disk1.name,
    azurerm_managed_disk.disk2.name,
    azurerm_managed_disk.disk3.name,
    azurerm_managed_disk.disk4.name,
    azurerm_managed_disk.disk5.name
  ]
}