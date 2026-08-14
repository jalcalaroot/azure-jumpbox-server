# ============================================================================
# Reference to the EXISTING resource group (created by the azure-virtual-
# network project). This project never creates or destroys the resource
# group, the VNet, or any of its subnets - it only reads the resource group
# as a data source and attaches new resources (NIC, VM) into the subnet
# whose ID is passed in via var.app_subnet_id.
# ============================================================================

data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

# ============================================================================
# Disposable SSH key pair for the management VM.
#
# Azure's API requires SOME authentication method to create a Linux VM -
# there is no fully "keyless" creation path. Since this VM has no network
# path reachable over SSH (private subnet, no public IP, NSG-Private denies
# all inbound), this key is never used for actual access.
#
# The private key is intentionally NOT written to disk - it only exists
# inside the Terraform state file for this project.
#
# Access to this VM is exclusively via:
#   - az vm run-command (Azure VM Agent, over the ARM control plane)
#   - Azure Serial Console
# ============================================================================

resource "tls_private_key" "mgmt" {
  algorithm = "RSA"
  rsa_bits  = 4096
}
