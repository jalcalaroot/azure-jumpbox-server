# ============================================================================
# Management VM - network interface
#
# Attached into the EXISTING App subnet (var.app_subnet_id), which lives in
# the separate network project. No public IP is attached - this NIC only
# has a private IP within that subnet's address range.
# ============================================================================

resource "azurerm_network_interface" "mgmt" {
  name                = "nic-mgmt-jumpbox"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing.name
  tags                = var.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = var.app_subnet_id
    private_ip_address_allocation = "Dynamic"
    # No public_ip_address_id - intentionally no public IP
  }
}

# ============================================================================
# Management VM
#
# Ubuntu Linux VM with no public IP and no inbound network exposure.
# Reachable only via:
#   - az vm run-command (Azure VM Agent, over the ARM control plane)
#   - Azure Serial Console (boot_diagnostics enabled below is required for
#     Serial Console to work)
#
# Network-level isolation (NSG-Private, route tables) is inherited from the
# subnet this VM is deployed into - that subnet's NSG already denies all
# inbound traffic by default, so no additional NSG resource is created here.
# ============================================================================

resource "azurerm_linux_virtual_machine" "mgmt" {
  name                = "vm-mgmt-jumpbox"
  location            = var.location
  resource_group_name = data.azurerm_resource_group.existing.name
  size                = var.mgmt_vm_size
  admin_username      = var.mgmt_admin_username
  zone                = var.mgmt_zone
  tags                = var.tags

  network_interface_ids = [
    azurerm_network_interface.mgmt.id,
  ]

  # Azure requires SOME authentication mechanism to create a Linux VM - there
  # is no "keyless" option in the API. Since this VM is never reached over
  # SSH (no public IP, no inbound NSG rule), we generate a disposable key
  # pair purely to satisfy that requirement. The private key is never
  # written to disk and never used - see data.tf.
  admin_ssh_key {
    username   = var.mgmt_admin_username
    public_key = tls_private_key.mgmt.public_key_openssh
  }

  os_disk {
    name                 = "osdisk-mgmt-jumpbox"
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Required for Azure Serial Console to function
  boot_diagnostics {
    storage_account_uri = null # null uses a Microsoft-managed storage account
  }

  disable_password_authentication = true
}
