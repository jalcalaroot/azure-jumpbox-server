output "mgmt_vm_id" {
  description = "ID of the isolated management VM"
  value       = azurerm_linux_virtual_machine.mgmt.id
}

output "mgmt_vm_private_ip" {
  description = "Private IP address of the management VM (no public IP exists for this resource)"
  value       = azurerm_network_interface.mgmt.private_ip_address
}
